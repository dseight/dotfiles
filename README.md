# dotfiles

Some configuration files and scripts that I use on my Linux and macOS machines.

## Installation

To install these configuration files on your machine, simply run this:

```console
./install.py
```

## Customization

To add or override some files, one can create another repo and include this one
as a submodule (in this example, called "public"). Then, write a customized
`install.py`, e.g.:

```python
#!/usr/bin/env python3

import sys
from pathlib import Path
from public.install import relocated
from public.install import DotfilesConfig, Installer, InstallerNotOnTTYException
from public.install import INSTALL_FILES as PUBLIC_FILES

INSTALL_FILES = {
    **relocated(PUBLIC_FILES, "public"),
    ".gitconfig": None,
    ".ssh/config": None,
}

if __name__ == "__main__":
    home = Path.home()
    config = DotfilesConfig(home / ".dotfiles")

    installer = Installer(home, config)
    installer.add_files(INSTALL_FILES)

    try:
        installer.install(interactive=True)
    except InstallerNotOnTTYException:
        print("Cannot run interactive install while not at TTY.")
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(0)
```
