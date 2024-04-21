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
from public.install import Cli, relocated
from public.install import INSTALL_FILES as PUBLIC_FILES

INSTALL_FILES = {
    **relocated(PUBLIC_FILES, "public"),
    ".gitconfig": None,
    ".ssh/config": None,
}

if __name__ == "__main__":
    cli = Cli()
    cli.installer.add_files(INSTALL_FILES)
    cli.run()
```
