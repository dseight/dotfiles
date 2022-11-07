#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2022 Dmitry Gerasimov <di.gerasimov@gmail.com>
# SPDX-License-Identifier: MIT

import argparse
import filecmp
import json
import shutil
import sys
from difflib import unified_diff
from pathlib import Path
from typing import Iterable, Set

INSTALL_FILES = (
    '.aliases',
    '.config/fish/conf.d/00-path-common.fish',
    '.config/fish/conf.d/00-path-darwin.fish',
    '.config/fish/conf.d/50-env.fish',
    '.config/fish/conf.d/abbreviations-git.fish',
    '.config/fish/conf.d/abbreviations-other.fish',
    '.config/fish/conf.d/aliases.fish',
    '.config/fish/conf.d/toolbox-prompt-color.fish',
    '.config/fish/config.fish',
    '.config/fish/functions/compiledb_sailfish.fish',
    '.config/fish/functions/nemodeploy.fish',
    '.config/fish/functions/nemosetup.fish',
    '.config/nvim/filetype.vim',
    '.config/nvim/init.vim',
    '.mersdkrc',
    '.mersdkuburc',
    '.sbrules',
    '.scripts/avg-time',
    '.scripts/check-qml-ids',
    '.scripts/colors',
    '.tmux.conf',
    '.vimrc',
    '.zshrc',
)

CL_RESET = '\033[m'
CL_RED = '\033[31m'
CL_GREEN = '\033[32m'
CL_CYAN = '\033[36m'
CL_FAINT_DEFAULT = '\033[2;39m'

use_color = sys.stdout.isatty()


def colorize(s: str, color: str) -> str:
    return color + s + CL_RESET if use_color else s


def color_diff(diff):
    for line in diff:
        if line.startswith('---') or line.startswith('+++'):
            yield colorize(line, CL_FAINT_DEFAULT)
        elif line.startswith('+'):
            yield colorize(line, CL_GREEN)
        elif line.startswith('-'):
            yield colorize(line, CL_RED)
        elif line.startswith('@@'):
            yield colorize(line, CL_CYAN)
        else:
            yield line


def get_git_revision() -> str:
    """
    Returns git revision from cwd. As git might be absent on a machine for some
    weird reason, just read file directly without executing git.
    """
    cwd = Path.cwd()
    head = cwd / '.git/HEAD'

    if not head.exists():
        return 'unknown'

    with open(head) as f:
        revision = f.readline().strip()

    if revision.startswith('ref: '):
        ref = revision[5:]
        with open(cwd / '.git' / ref) as f:
            revision = f.readline().strip()

    return revision


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
            self._installed = set(content['installed'])

    def installed(self) -> Set[str]:
        return self._installed

    def add(self, path: str):
        self._installed.add(path)

    def remove(self, path: str):
        self._installed.remove(path)

    def save(self):
        content = {
            'version': self._VERSION,
            'revision': get_git_revision(),
            'installed': list(sorted(self._installed)),
        }

        with open(self._path, 'w') as f:
            json.dump(content, f, indent=4)


class _InstallationEntry:

    def __init__(self, name: str, src: str, dst: Path):
        # Name of file relative to the install path
        self.name = name
        # Actual file location to copy from
        self.src = src
        # Full path to the file install location
        self.dst = dst


class InstallerNotOnTTYException(Exception):
    ...


class Installer:

    def __init__(self, install_root: Path, config: DotfilesConfig):
        self._install_root = install_root
        self._config = config

        self._entries: Iterable[_InstallationEntry] = []
        self._new: Iterable[_InstallationEntry] = []
        self._changed: Iterable[_InstallationEntry] = []
        self._removed: Iterable[str] = []

    def add(self, files: Iterable[str], base: str = ''):
        """
        Add list of files to install.

        :param files: list of files to install
        :param base: base directory where files these files are located
        """
        for f in files:
            entry = _InstallationEntry(f, base + f, self._install_root / f)
            self._entries.append(entry)

    def install(self, interactive: bool):
        self._collect_changes()

        if interactive:
            self._print_changes_summary()
            self._install(self._interactive_install_file)
        else:
            self._install(self._install_file)

        self._config.save()

    def _collect_changes(self):
        for e in self._entries:
            if not e.dst.exists():
                self._new.append(e)
            elif e.name not in self._config.installed():
                print(f'Warning: "{e.name}" already installed but untracked')
                if filecmp.cmp(e.src, e.dst):
                    self._new.append(e)
                else:
                    self._changed.append(e)
            elif not filecmp.cmp(e.src, e.dst):
                self._changed.append(e)

        names_to_install = set(map(lambda e: e.name, self._entries))

        self._removed = list(filter(
            lambda f: f not in names_to_install, self._config.installed()))

    def _print_changes_summary(self):
        if self._new:
            pretty_new = map(lambda e: '\n\t' +
                             colorize(e.name, CL_GREEN), self._new)
            print('New files:',
                  ''.join(pretty_new), end='\n\n')

        if self._changed:
            pretty_changed = map(lambda e: '\n\t' +
                                 colorize(e.name, CL_RED), self._changed)
            print('Modified files:',
                  ''.join(pretty_changed), end='\n\n')

        if self._removed:
            pretty_removed = map(lambda x: '\n\t' +
                                 colorize(x, CL_RED), self._removed)
            print('Removed files:',
                  ''.join(pretty_removed), end='\n\n')

        if not sys.stdout.isatty():
            raise InstallerNotOnTTYException()

    @staticmethod
    def _print_file_diff(src, dst):
        with open(src) as f:
            src_lines = f.readlines()

        with open(dst) as f:
            dst_lines = f.readlines()

        diff = unified_diff(dst_lines, src_lines,
                            fromfile=str(dst), tofile=str(src))
        diff = color_diff(diff)

        sys.stdout.writelines(diff)

    def _install(self, install_changed_file):
        for e in self._new:
            self._install_file(e.src, e.dst)

        for e in self._changed:
            install_changed_file(e.src, e.dst)

        for src in self._removed:
            self._remove_file(src)

    def _interactive_install_file(self, src, dst):
        self._print_file_diff(src, dst)

        query = input('\nApply changes (y/N)? ')
        if query.lower() != 'y':
            return

        self._install_file(src, dst)
        print('Changes applied for', dst)

    def _install_file(self, src: Path, dst: Path):
        dst.parent.mkdir(0o755, parents=True, exist_ok=True)
        shutil.copy(src, dst)
        self._config.add(src)

    def _remove_file(self, src: Path):
        dst = self._install_root / src
        dst.unlink(missing_ok=True)
        self._config.remove(src)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Install or update dotfiles.')
    parser.add_argument('-y', '--non-interactive', action='store_true',
                        help='install files in non-interactive mode')
    args = parser.parse_args()

    home = Path.home()
    config = DotfilesConfig(home / '.dotfiles')
    installer = Installer(home, config)
    installer.add(INSTALL_FILES)

    try:
        installer.install(not args.non_interactive)
    except InstallerNotOnTTYException:
        print('Cannot run interactive install while not at TTY. ' +
              'Please review the changes manually and run again ' +
              'with -y/--non-interactive.')
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(0)
