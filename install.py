#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2022-2024 Dmitry Gerasimov <di.gerasimov@gmail.com>
# SPDX-License-Identifier: MIT

import argparse
import filecmp
import json
import shutil
import sys
import subprocess
from difflib import unified_diff
from pathlib import Path
from typing import Dict, Iterable, List, Set

INSTALL_FILES = (
    ".aliases",
    ".config/fish/conf.d/00-path-common.fish",
    ".config/fish/conf.d/00-path-darwin.fish",
    ".config/fish/conf.d/50-env.fish",
    ".config/fish/conf.d/abbreviations-git.fish",
    ".config/fish/conf.d/abbreviations-other.fish",
    ".config/fish/conf.d/aliases.fish",
    ".config/fish/conf.d/toolbox-prompt-color.fish",
    ".config/fish/config.fish",
    ".config/fish/functions/compiledb_sailfish.fish",
    ".config/fish/functions/nemodeploy.fish",
    ".config/fish/functions/nemosetup.fish",
    ".config/nvim/filetype.vim",
    ".config/nvim/init.vim",
    ".config/wezterm/colors/PaulMillrTweaked.toml",
    ".config/wezterm/wezterm.lua",
    ".mersdkrc",
    ".mersdkuburc",
    ".sbrules",
    ".scripts/avg-time",
    ".scripts/check-qml-ids",
    ".scripts/colors",
    ".tmux.conf",
    ".vimrc",
    ".zshrc",
)

INSTALL_COMMON_VIM_PLUGINS = {
    "ntpeters/vim-better-whitespace": "029f35c783f1b504f9be086b9ea757a36059c846",
}
INSTALL_NEOVIM_PLUGINS = {
    **INSTALL_COMMON_VIM_PLUGINS,
    "folke/which-key.nvim": "4433e5ec9a507e5097571ed55c02ea9658fb268a",
    "ibhagwan/fzf-lua": "97a88bb8b0785086d03e08a7f98f83998e0e1f8a",
    "lewis6991/gitsigns.nvim": "6ef8c54fb526bf3a0bc4efb0b2fe8e6d9a7daed2",
    "miikanissi/modus-themes.nvim": "7cef53b10b6964a0be483fa27a3d66069cefaa6c",
    "nvim-lualine/lualine.nvim": "0a5a66803c7407767b799067986b4dc3036e1983",
    "nvim-treesitter/nvim-treesitter": "7e6b044be8187c4c28dffa90ad0dc623dbe243f3",
}
INSTALL_VIM_PLUGINS = {
    **INSTALL_COMMON_VIM_PLUGINS,
    "itchyny/lightline.vim": "58c97bc21c6f657d3babdd4eefce7593e30e75ce",
    "itchyny/vim-gitbranch": "1a8ba866f3eaf0194783b9f8573339d6ede8f1ed",
    "sheerun/vim-polyglot": "bc8a81d3592dab86334f27d1d43c080ebf680d42",
}

CL_RESET = "\033[m"
CL_RED = "\033[31m"
CL_GREEN = "\033[32m"
CL_CYAN = "\033[36m"
CL_FAINT_DEFAULT = "\033[2;39m"

use_color = sys.stdout.isatty()


def colorize(s: str, color: str) -> str:
    return color + s + CL_RESET if use_color else s


def color_diff(diff):
    for line in diff:
        if line.startswith("---") or line.startswith("+++"):
            yield colorize(line, CL_FAINT_DEFAULT)
        elif line.startswith("+"):
            yield colorize(line, CL_GREEN)
        elif line.startswith("-"):
            yield colorize(line, CL_RED)
        elif line.startswith("@@"):
            yield colorize(line, CL_CYAN)
        else:
            yield line


def get_dotfiles_revision() -> str:
    # Use sys.argv[0] instead of __file__ because this function can be called
    # from a script in another directory. E.g. install.py might be imported
    # from another script, and in this case revision of *that* repo should be
    # used instead).
    dotfiles_root = Path(sys.argv[0]).parent.resolve()

    return (
        subprocess.check_output(("git", "-C", str(dotfiles_root), "rev-parse", "HEAD"))
        .decode()
        .strip()
    )


class InstallationObject:
    def __init__(self, dst_rel: Path, root: Path):
        # Relative installation path
        self.dst_rel = dst_rel
        self.root = root

    @property
    def dst(self) -> Path:
        """Full installation path"""
        return self.root / self.dst_rel

    def changed(self) -> bool:
        raise NotImplementedError

    def print_diff(self):
        raise NotImplementedError

    def install(self):
        raise NotImplementedError


class File(InstallationObject):
    def __init__(self, src: Path, dst_rel: Path, root: Path):
        super().__init__(dst_rel, root)
        # Full path to the source
        self.src = src

    def changed(self) -> bool:
        return not filecmp.cmp(self.src, self.dst)

    def print_diff(self):
        with open(self.src, encoding="utf-8") as f:
            src_lines = f.readlines()

        with open(self.dst, encoding="utf-8") as f:
            dst_lines = f.readlines()

        diff = unified_diff(
            dst_lines, src_lines, fromfile=str(self.dst), tofile=str(self.src)
        )
        diff = color_diff(diff)

        sys.stdout.writelines(diff)

    def install(self):
        self.dst.parent.mkdir(0o755, parents=True, exist_ok=True)
        shutil.copy(self.src, self.dst)


class Repo(InstallationObject):
    def __init__(self, url: str, rev: str, dst_rel: Path, root: Path):
        super().__init__(dst_rel, root)
        self.url = url
        self.rev = rev

    def changed(self) -> bool:
        return (
            self._get_current_revision() != self.rev
            or self._get_current_remote_url() != self.url
        )

    def print_diff(self):
        old = [
            f"commit {self._get_current_revision()}\n",
            f"remote {self._get_current_remote_url()}\n",
        ]
        new = [
            f"commit {self.rev}\n",
            f"remote {self.url}\n",
        ]

        diff = unified_diff(old, new, fromfile=str(self.dst), tofile=str(self.dst))
        diff = color_diff(diff)

        sys.stdout.writelines(diff)

    def install(self):
        if not Path(self.dst / ".git").exists():
            self._clone()
            return

        if self._get_current_remote_url() != self.url:
            self._git("remote", "set-url", "origin", self.url)

        self._git("fetch")
        self._git("checkout", "-q", self.rev)

    def _clone(self):
        self.dst.parent.mkdir(0o755, parents=True, exist_ok=True)
        subprocess.check_call(("git", "clone", self.url, str(self.dst)))

        try:
            self._git("checkout", "-q", self.rev)
        except subprocess.CalledProcessError:
            # Don't leave repo checked out on an unknown revision, just remove
            # it completely
            shutil.rmtree(self.dst)
            raise

    def _git(self, *args):
        subprocess.check_call(("git", "-C", str(self.dst), *args))

    def _git_output(self, *args) -> str:
        return (
            subprocess.check_output(("git", "-C", str(self.dst), *args))
            .decode()
            .strip()
        )

    def _get_current_revision(self) -> str:
        return self._git_output("rev-parse", "HEAD")

    def _get_current_remote_url(self) -> str:
        return self._git_output("remote", "get-url", "origin")


class VimPlugin(Repo):
    def __init__(self, name: str, rev: str, root: Path, neovim: bool):
        dst_name = name.split("/")[-1]
        if neovim:
            dst_rel = Path(f".local/share/nvim/site/pack/default/start/{dst_name}")
        else:
            dst_rel = Path(f".vim/pack/default/start/{dst_name}")
        super().__init__(f"https://github.com/{name}.git", rev, dst_rel, root)


class DotfilesConfig:
    # If config format needs to be changed, version *must* be bumped,
    # and migrations have to be written
    _VERSION = 1

    def __init__(self, path: Path):
        self._path = path
        self._installed = set()

        if not path.exists():
            return

        with open(self._path, encoding="utf-8") as f:
            content = json.load(f)
            self._installed = set(map(Path, content["installed"]))

    def installed(self) -> Set[Path]:
        return self._installed

    def add(self, path: Path):
        self._installed.add(path)

    def remove(self, path: Path):
        self._installed.remove(path)

    def save(self):
        content = {
            "version": self._VERSION,
            "revision": get_dotfiles_revision(),
            "installed": list(sorted(map(str, self._installed))),
        }

        with open(self._path, "w", encoding="utf-8") as f:
            json.dump(content, f, indent=4)


class InstallerNotOnTTYException(Exception): ...


class Installer:
    def __init__(self, install_root: Path, config: DotfilesConfig):
        self._install_root = install_root
        self._config = config

        self._objects: List[InstallationObject] = []
        self._new: List[InstallationObject] = []
        self._changed: List[InstallationObject] = []
        self._removed: List[Path] = []

    def add_files(self, files: Iterable[str], base: str = ""):
        """
        Add list of files to install.

        :param files: list of files to install
        :param base: base directory where these files are located
        """
        for f in files:
            o = File(Path(base + f), Path(f), self._install_root)
            self._objects.append(o)

    def add_vim_plugins(self, plugins: Dict[str, str], neovim: bool = False):
        for name, rev in plugins.items():
            o = VimPlugin(name, rev, self._install_root, neovim)
            self._objects.append(o)

    def install(self, interactive: bool):
        self._collect_changes()

        if interactive:
            if not sys.stdout.isatty():
                raise InstallerNotOnTTYException()
            self._print_changes()
            query = input("\nContinue (y/N)? ")
            if query.lower() != "y":
                return
            self._apply_changes(self._interactive_install, self._interactive_remove)
        else:
            self._apply_changes(self._install, self._remove)

        self._config.save()

    def preview(self):
        self._collect_changes()
        self._print_changes()
        for o in self._changed:
            o.print_diff()

    def _collect_changes(self):
        for o in self._objects:
            if not o.dst.exists():
                self._new.append(o)
            elif o.dst_rel not in self._config.installed():
                print(f'Warning: "{o.dst_rel}" already installed but untracked')
                if o.changed():
                    self._changed.append(o)
                else:
                    self._new.append(o)
            elif o.changed():
                self._changed.append(o)

        to_install = set(map(lambda o: o.dst_rel, self._objects))

        self._removed = list(
            filter(lambda f: f not in to_install, self._config.installed())
        )

    def _print_changes(self):
        if self._new:
            pretty_new = map(
                lambda o: "\n\t" + colorize(str(o.dst_rel), CL_GREEN), self._new
            )
            print("New:", "".join(pretty_new), end="\n\n")

        if self._changed:
            pretty_changed = map(
                lambda o: "\n\t" + colorize(str(o.dst_rel), CL_RED), self._changed
            )
            print("Modified:", "".join(pretty_changed), end="\n\n")

        if self._removed:
            pretty_removed = map(
                lambda path: "\n\t" + colorize(str(path), CL_RED), self._removed
            )
            print("Removed:", "".join(pretty_removed), end="\n\n")

    def _apply_changes(self, install_changed, remove):
        for o in self._new:
            self._install(o)

        for o in self._changed:
            install_changed(o)

        for path in self._removed:
            remove(path, self._install_root / path)

    def _interactive_install(self, o: InstallationObject):
        o.print_diff()

        query = input("\nApply changes (y/N)? ")
        if query.lower() != "y":
            return

        self._install(o)
        print("Changes applied for", o.dst)

    def _install(self, o: InstallationObject):
        o.install()
        self._config.add(o.dst_rel)

    def _interactive_remove(self, path: Path, full_path: Path):
        query = input(f'\nRemove "{full_path}" (y/N)? ')
        if query.lower() == "y":
            self._remove(path, full_path)

    def _remove(self, path: Path, full_path: Path):
        # At the moment of removal the type of an installation object is
        # already lost, so just try to guess what to do with the given path.
        # The better way would probably be splitting files and repos handling
        # in the DotfilesConfig.
        if full_path.is_dir():
            shutil.rmtree(full_path)
        else:
            full_path.unlink(missing_ok=True)
        self._config.remove(path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Install or update dotfiles.")
    parser.add_argument(
        "-y",
        "--non-interactive",
        action="store_true",
        help="install files in non-interactive mode",
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="print what's changed without installing",
    )
    args = parser.parse_args()

    home = Path.home()
    config = DotfilesConfig(home / ".dotfiles")
    installer = Installer(home, config)
    installer.add_files(INSTALL_FILES)
    installer.add_vim_plugins(INSTALL_NEOVIM_PLUGINS, neovim=True)
    installer.add_vim_plugins(INSTALL_VIM_PLUGINS)

    if args.dry_run:
        installer.preview()
        sys.exit(0)

    try:
        installer.install(not args.non_interactive)
    except InstallerNotOnTTYException:
        print(
            "Cannot run interactive install while not at TTY. "
            + "Please review the changes manually and run again "
            + "with -y/--non-interactive."
        )
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(0)
