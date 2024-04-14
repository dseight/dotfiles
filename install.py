#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2022-2024 Dmitry Gerasimov <di.gerasimov@gmail.com>
# SPDX-License-Identifier: MIT

import argparse
import filecmp
import json
import shutil
import sys
from difflib import unified_diff
from pathlib import Path
from typing import Iterable, List, Set

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


def get_git_revision() -> str:
    """
    Returns git revision from cwd. As git might be absent on a machine for some
    weird reason, just read file directly without executing git.
    """
    cwd = Path.cwd()
    head = cwd / ".git/HEAD"

    if not head.exists():
        return "unknown"

    with open(head) as f:
        revision = f.readline().strip()

    if revision.startswith("ref: "):
        ref = revision[5:]
        with open(cwd / ".git" / ref) as f:
            revision = f.readline().strip()

    return revision


class InstallationObject:
    def __init__(self, dst_rel: Path, root: Path):
        # Relative installation path
        self.dst_rel = dst_rel
        # Full installation path
        self.dst = root / dst_rel

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
        with open(self.src) as f:
            src_lines = f.readlines()

        with open(self.dst) as f:
            dst_lines = f.readlines()

        diff = unified_diff(
            dst_lines, src_lines, fromfile=str(self.dst), tofile=str(self.src)
        )
        diff = color_diff(diff)

        sys.stdout.writelines(diff)

    def install(self):
        self.dst.parent.mkdir(0o755, parents=True, exist_ok=True)
        shutil.copy(self.src, self.dst)


class DotfilesConfig:
    # If config format needs to be changed, version *must* be bumped,
    # and migrations have to be written
    _VERSION = 1

    def __init__(self, path: Path):
        self._path = path
        self._installed = set()

        if not path.exists():
            return

        with open(self._path) as f:
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
            "revision": get_git_revision(),
            "installed": list(sorted(map(str, self._installed))),
        }

        with open(self._path, "w") as f:
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

    def install(self, interactive: bool):
        self._collect_changes()

        if interactive:
            if not sys.stdout.isatty():
                raise InstallerNotOnTTYException()
            self._print_changes()
            self._apply_changes(self._interactive_install, self._interactive_remove)
        else:
            self._apply_changes(self._install, self._remove)

        self._config.save()

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
    args = parser.parse_args()

    home = Path.home()
    config = DotfilesConfig(home / ".dotfiles")
    installer = Installer(home, config)
    installer.add_files(INSTALL_FILES)

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
