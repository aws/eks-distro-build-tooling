# From https://github.com/GoogleContainerTools/distroless/blob/main/experimental/python3/testdata/python3.yaml

import pkgutil
skip_modules = frozenset((
  # Windows-specific modules
  'asyncio.windows_events',
  'asyncio.windows_utils',
  'ctypes.wintypes',
  'distutils._msvccompiler',
  'distutils.command.bdist_msi',
  'distutils.msvc9compiler',
  'encodings.cp65001',
  'encodings.mbcs',
  'encodings.oem',
  'multiprocessing.popen_spawn_win32',
  'winreg',
  # Python regression tests "for internal use by Python only"
  'test',
  # calls sys.exit
  'unittest.__main__',
  'venv.__main__',
  # depends on things not installed by default on Debian
  'dbm.gnu',
  'lib2to3.pgen2.conv',
  'turtle',
  # added for 3.9 build from source, this module does not seem to be included in the al2 package
  'ctypes.test.__main__',
))
# pass an error handler so the test fails if there are broken standard library packages
def walk_packages_onerror(failed_module_name):
  raise Exception('failed to import module: {}'.format(repr(failed_module_name)))
for module_info in pkgutil.walk_packages(onerror=walk_packages_onerror):
  module_name = module_info.name
  if module_name in skip_modules or module_name.startswith('test.'):
    continue
  print('importing {}'.format(module_name))
  __import__(module_name)
  print('imported {}'.format(module_name))
# ensures some module does not exit early (e.g unittest.__main__)
print('FINISHED ENTIRE SCRIPT')