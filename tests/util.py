import importlib
import importlib.util
import os
import sys

__dir = os.path.dirname(os.path.realpath(__file__))

# Allow import of arbitrary files (without .py extension)
importlib.machinery.SOURCE_SUFFIXES.append("")


def import_module_abs(path, name=None):
    if name is None:
        name = os.path.basename(path)
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def import_module(path, name=None):
    abs_path = os.path.join(__dir, "../", path)
    return import_module_abs(abs_path, name)
