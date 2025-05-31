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
from typing import Dict, List, Optional, Set

# installation path -> path in repo. None implies "use the same path".
INSTALL_FILES: Dict[str, Optional[str]] = {
    ".aliases": None,
    ".config/fish/conf.d/00-path-common.fish": None,
    ".config/fish/conf.d/00-path-darwin.fish": None,
    ".config/fish/conf.d/50-env.fish": None,
    ".config/fish/conf.d/abbreviations-git.fish": None,
    ".config/fish/conf.d/abbreviations-other.fish": None,
    ".config/fish/conf.d/aliases.fish": None,
    ".config/fish/conf.d/toolbox-prompt-color.fish": None,
    ".config/fish/config.fish": None,
    ".config/fish/functions/compiledb_kernel.fish": None,
    ".config/fish/functions/compiledb_sailfish.fish": None,
    ".config/fish/functions/fish_jobs_prompt.fish": None,
    ".config/fish/functions/fish_prompt.fish": None,
    ".config/fish/functions/man.fish": None,
    ".config/fish/functions/nemodeploy.fish": None,
    ".config/fish/functions/nemosetup.fish": None,
    ".config/nvim/filetype.vim": None,
    ".config/nvim/init.vim": None,
    ".config/wezterm/colors/PaulMillrTweaked.toml": None,
    ".config/wezterm/colors/PaulMillrTweakedLight.toml": None,
    ".config/wezterm/wezterm.lua": None,
    ".gitconfig": None,
    ".mersdkrc": None,
    ".mersdkuburc": None,
    ".sbrules": None,
    ".scripts/avg-time": None,
    ".scripts/check-qml-ids": None,
    ".scripts/colors": None,
    ".tmux.conf": None,
    ".typos.toml": None,
    ".vimrc": None,
    ".zshrc": None,
}

INSTALL_COMMON_VIM_PLUGINS = {
    "christoomey/vim-tmux-navigator": "5b3c701686fb4e6629c100ed32e827edf8dad01e",
    "ntpeters/vim-better-whitespace": "029f35c783f1b504f9be086b9ea757a36059c846",
}
INSTALL_NEOVIM_PLUGINS = {
    **INSTALL_COMMON_VIM_PLUGINS,
    "folke/which-key.nvim": "4b7167f8fb2dba3d01980735e3509e172c024c29",
    "dseight/fzf-lua": "69347be49fab4337dc5fa6bb96fd61e73909b1a8",
    "lewis6991/gitsigns.nvim": "76927d14d3fbd4ba06ccb5246e79d93b5442c188",
    "mfussenegger/nvim-lint": "f707b3ae50417067fa63fdfe179b0bff6b380da1",
    "miikanissi/modus-themes.nvim": "ad9910a0e5055a00b1e14b507902b2a7a7fe449e",
    "neovim/nvim-lspconfig": "7133e85c3df14a387da8942c094c7edddcdef309",
    "nvim-lualine/lualine.nvim": "544dd1583f9bb27b393f598475c89809c4d5e86b",
    "dseight/nvim-treesitter": "049906433ead412c80fff1116c648c09f45a0b0a",
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


def relocated(files: Dict[str, Optional[str]], path: str) -> Dict[str, str]:
    """
    Return dict with files, where their source is relocated to a specified dir.
    Just a helper for usage in private dotfiles.

    :param files: dict with dst_rel to src mappings
    :param path: relocation path
    """
    result: Dict[str, str] = {}

    for k, v in files.items():
        src = v if v else k
        result[k] = f"{path}/{src}"

    return result


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

    def add_files(self, files: Dict[str, Optional[str]]):
        """
        Add list of files to install.

        :param files: a map of files to install. Where the key is a relative
            destination, and the value is the source. If the source is None,
            then the relative destination will be used as a relative source
            (from cwd).
        """
        for dst_rel, src in files.items():
            if src:
                o = File(Path(src), Path(dst_rel), self._install_root)
            else:
                o = File(Path(dst_rel), Path(dst_rel), self._install_root)
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


class Cli:
    def __init__(self):
        home = Path.home()
        config = DotfilesConfig(home / ".dotfiles")
        self.installer = Installer(home, config)

    def run(self):
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

        if args.dry_run:
            self.installer.preview()
            sys.exit(0)

        try:
            self.installer.install(not args.non_interactive)
        except InstallerNotOnTTYException:
            print(
                "Cannot run interactive install while not at TTY. "
                + "Please review the changes manually and run again "
                + "with -y/--non-interactive."
            )
            sys.exit(1)
        except KeyboardInterrupt:
            sys.exit(0)


if __name__ == "__main__":
    cli = Cli()
    cli.installer.add_files(INSTALL_FILES)
    cli.installer.add_vim_plugins(INSTALL_NEOVIM_PLUGINS, neovim=True)
    cli.installer.add_vim_plugins(INSTALL_VIM_PLUGINS)
    cli.run()
