import argparse
import json
import os
import platform
import sys

from jupyter_client.kernelspec import KernelSpecManager
from IPython.utils.tempdir import TemporaryDirectory


def main():
  args = parse_args()

  if platform.system() == 'Linux':
    lldb_python = '%s/usr/lib/python2.7/site-packages' % args.swift_toolchain
    swift_libs = '%s/usr/lib/swift/linux' % args.swift_toolchain
    repl_swift = '%s/usr/bin/repl_swift' % args.swift_toolchain
  elif platform.system() == 'Darwin':
    lldb_python = '%s/System/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/Python' % args.swift_toolchain
    swift_libs = '%s/usr/lib/swift/macosx' % args.swift_toolchain
    repl_swift = '%s/System/Library/PrivateFrameworks/LLDB.framework/Resources/repl_swift' % args.swift_toolchain
  else:
    raise Exception('Unknown system %s' % platform.system())

  script_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
  kernel_json = {
    'argv': [
        sys.executable,
        '%s/swift_kernel.py' % script_dir,
        '-f',
        '{connection_file}',
    ],
    'display_name': 'Swift',
    'language': 'swift',
    'env': {
      'PYTHONPATH': lldb_python,
      'LD_LIBRARY_PATH': swift_libs,
      'REPL_SWIFT_PATH': repl_swift,
    },
  }
  print('kernel.json is\n%s' % json.dumps(kernel_json, indent=2))

  with TemporaryDirectory() as td:
    os.chmod(td, 0o755)
    with open(os.path.join(td, 'kernel.json'), 'w') as f:
      json.dump(kernel_json, f, indent=2)
    KernelSpecManager().install_kernel_spec(
        td, 'swift', user=args.user, prefix=args.prefix, replace=True)

  print('Registered kernel!')


def parse_args():
  parser = argparse.ArgumentParser(
      description='Register KernelSpec for Swift Kernel')

  prefix_locations = parser.add_mutually_exclusive_group()
  prefix_locations.add_argument(
      '--user',
      help='Register KernelSpec in user homedirectory',
      action='store_true')
  prefix_locations.add_argument(
      '--sys-prefix',
      help='Register KernelSpec in sys.prefix. Useful in conda / virtualenv',
      action='store_true',
      dest='sys_prefix')
  prefix_locations.add_argument(
      '--prefix',
      help='Register KernelSpec in this prefix',
      default=None)

  parser.add_argument(
      '--swift-toolchain',
      help='Path to the swift toolchain')

  args = parser.parse_args()
  if args.sys_prefix:
    args.prefix = sys.prefix
  args.swift_toolchain = os.path.realpath(args.swift_toolchain)
  return args


if __name__ == '__main__':
  main()
