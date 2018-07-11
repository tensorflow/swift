#!/usr/bin/python
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import lldb
import sys
import os

from ipykernel.kernelbase import Kernel


class SwiftKernel(Kernel):
    implementation = 'SwiftKernel'
    implementation_version = '0.1'
    banner = ''

    language_info = {
        'name': 'swift',
        'mimetype': 'text/x-swift',
        'file_extension': '.swift',
    }

    def __init__(self, **kwargs):
        super(SwiftKernel, self).__init__(**kwargs)

        self.debugger = lldb.SBDebugger.Create()
        self.debugger.SetAsync(False)
        if not self.debugger:
            raise Exception('Could not start debugger')

        # LLDB crashes while trying to load some Python stuff on Mac. Maybe
        # something is misconfigured? This works around the problem by telling
        # LLDB not to load the Python scripting stuff, which we don't use
        # anyways.
        self.debugger.SetScriptLanguage(lldb.eScriptLanguageNone)

        repl_swift = os.environ['REPL_SWIFT_PATH']
        self.target = self.debugger.CreateTargetWithFileAndArch(repl_swift, '')
        if not self.target:
            raise Exception('Could not create target %s' % repl_swift)

        self.main_bp = self.target.BreakpointCreateByName(
            'repl_main', self.target.GetExecutable().GetFilename())
        if not self.main_bp:
            raise Exception('Could not set breakpoint')

        self.process = self.target.LaunchSimple(None, None, os.getcwd())
        if not self.process:
            raise Exception('Could not launch process')

        self.expr_opts = lldb.SBExpressionOptions()
        swift_language = lldb.SBLanguageRuntime.GetLanguageTypeFromString(
            'swift')
        self.expr_opts.SetLanguage(swift_language)
        self.expr_opts.SetREPLMode(True)

    def do_execute(self, code, silent, store_history=True,
                   user_expressions=None, allow_stdin=False):
        # Execute the code.
        result = self.target.EvaluateExpression(str(code), self.expr_opts)

        # Send stdout to the client.
        while True:
            BUFFER_SIZE = 1000
            stdout_buffer = self.process.GetSTDOUT(BUFFER_SIZE)
            if len(stdout_buffer) == 0:
                break
            self.send_response(self.iopub_socket, 'stream', {
                'name': 'stdout',
                'text': stdout_buffer
            })

        if result.error.type == lldb.eErrorTypeInvalid:
            # Success, with value.
            self.send_response(self.iopub_socket, 'execute_result', {
                'execution_count': self.execution_count,
                'data': {
                    'text/plain': result.description
                }
            })

            return {
                'status': 'ok',
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {}
            }
        elif result.error.type == lldb.eErrorTypeGeneric:
            # Success, without value.
            return {
                'status': 'ok',
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {}
            }
        else:
            # Error!
            self.send_response(self.iopub_socket, 'error', {
                'execution_count': self.execution_count,
                'ename': '',
                'evalue': '',
                'traceback': [result.error.description],
            })

            return {
                'status': 'error',
                'execution_count': self.execution_count,
                'ename': '',
                'evalue': '',
                'traceback': [result.error.description],
            }


if __name__ == '__main__':
    from ipykernel.kernelapp import IPKernelApp
    IPKernelApp.launch_instance(kernel_class=SwiftKernel)
