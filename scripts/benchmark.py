#!/usr/bin/env python3
"""
Testing script for compilation coverage.

Receives a circom file to be sent to the compiler and an output path for the report.
"""
import glob
import json
import os
import os.path
import re
import subprocess
import tempfile
import time
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Tuple, List, Match, Union, Optional
import click


GLOB = "tests/vulnerabilities/**/test.json"


def setup_dirs(src: str, out: str) -> Tuple[str, str, TemporaryDirectory]:
    src = os.path.realpath(src)
    out = os.path.realpath(out)
    tmp = TemporaryDirectory()
    return src, out, tmp


def check_is_missing_feature(fd) -> Match[str] | None:
    fd.seek(0)
    for line in fd:
        check = re.compile(r"thread 'main' panicked at 'not yet implemented', (.*):(.*):(.*)")
        match = check.match(line.decode("utf-8"))
        if match is not None:
            return match
    return


def check_is_other_panic(fd) -> Match[str] | None:
    fd.seek(0)
    for line in fd:
        check = re.compile(r"thread 'main' panicked at (.*), (.*):(.*):(.*)")
        match = check.match(line.decode("utf-8"))
        if match is not None:
            return match
    return


def is_circom_error(fd) -> bool:
    fd.seek(0)
    for line in fd:
        if re.compile(r"^error\[.*\]:").match(line.decode("utf-8")) is not None:
            return True
    return False


def is_llvm_validation_error(fd) -> bool:
    fd.seek(0)
    for line in fd:
        if "LLVM Module verification failed" in line.decode("utf-8"):
            return True
    return False


def non_constant_id(fd) -> bool:
    fd.seek(0)
    for line in fd:
        if "is_constant_int()" in line.decode("utf-8"):
            return True
    return False


class TimedOutExecution:
    def __init__(self, exception: subprocess.TimeoutExpired):
        self.exception = exception
        self.returncode = 1

    @property
    def stdout(self):
        return self.exception.stdout

    @property
    def stderr(self):
        return self.exception.stderr


def extract_number_templates(message) -> int:
    for line in message.splitlines():
        check = re.compile(r"template instances: (\d*)")
        match = check.match(line)
        if match:
            return int(match.group(1))
    return -1


class Report:
    def __init__(self, src: str, cmd: List[str], execution: Union[subprocess.CompletedProcess | TimedOutExecution], run_time: float, stderr):
        self.src = src
        self.cmd = cmd
        self.execution = execution
        self.run_time = run_time
        self.test_id = None
        self._stderr = stderr

    @property
    def successful(self):
        return self.execution.returncode == 0

    @property
    def missing_feature(self):
        match = check_is_missing_feature(self.stderr)
        if match:
            return {
                "file": match.group(1),
                "line": match.group(2),
                "column": match.group(3)
            }

    @property
    def has_panic(self):
        match = check_is_other_panic(self.stderr)
        if match:
            return {
                "file": match.group(2),
                "line": match.group(3),
                "column": match.group(4),
                "message": match.group(1)
            }

    @property
    def stderr(self):
        #if self.execution.stderr:
        #    return escape_ansi(self.execution.stderr.decode("utf-8"))
        #return ""
        return self._stderr

    @property
    def stdout(self):
        #if self.execution.stdout:
        #    return escape_ansi(self.execution.stdout.decode("utf-8"))
        return ""

    @property
    def error_class(self):
        if self.successful:
            return "none"
        if is_circom_error(self.stderr):
            return "circom"
        if self.missing_feature is not None:
            return "todo!"
        if self.has_panic is not None:
            return "panic!"
        if is_llvm_validation_error(self.stderr):
            return "invalid llvm ir"
        if non_constant_id(self.stderr):
            return "non constant indexing"
        if isinstance(self.execution, TimedOutExecution):
            return "timeout"
        return "other"

    def to_dict(self) -> dict:
        return {
            'src': self.src,
            'cmd': self.cmd,
            'return_code': self.execution.returncode,
            'successful': self.successful,
            'run_time': self.run_time,
            'missing_feature': self.missing_feature,
            'error_class': self.error_class,
            'panicked': self.has_panic,
            'test_id': self.test_id,
            #'template_instances': extract_number_templates(self.stdout)
        }


def escape_ansi(line: str) -> str:
    ansi_escape = re.compile(r'(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]')
    return ansi_escape.sub('', line)


def tail(f):
    execution = subprocess.run(['tail', f.name], capture_output=True)
    if execution.returncode == 0:
        if execution.stdout:
            print(escape_ansi(execution.stdout.decode("utf-8")))
    else:
        print(execution.stderr.decode("utf-8"))
        exit(1)


def run_test(src: str, circom: str, debug: bool, cwd: str, libs_path: Optional[str], timeout: int) -> Report:
    src = os.path.realpath(src)
    tmp = TemporaryDirectory()
    stderr = tempfile.NamedTemporaryFile()
    cmd = [
        circom,
        '--llvm',
        '--summary',
        '-o', tmp.name
    ]
    if libs_path:
        cmd.extend(['-l', libs_path])
    cmd.append(src)
    print("Source file:", src)
    try:
        start = time.time()
        execution = subprocess.run(cmd, stderr=stderr, stdout=subprocess.DEVNULL, cwd=cwd, timeout=timeout)
        end = time.time()
        if execution.returncode == 0:
            print("Success!")
        else:
            print("Failure!")
            print("CMD:", ' '.join(cmd))
        if debug:
            # if execution.stdout:
            #     print("Circom stdout:\n", escape_ansi(execution.stdout.decode("utf-8")))
            print("Circom stderr:\n")
            tail(stderr)
            print("Execution time in seconds:", end - start)

        return Report(src, cmd, execution, end - start, stderr)
    except subprocess.TimeoutExpired as e:
        print("Test timed out!")
        print("CMD:", ' '.join(cmd))
        return Report(src, cmd, TimedOutExecution(e), timeout, stderr)


def check_link_libraries(data: dict) -> bool:
    """The link_libraries is an optional field that defaults to True."""
    if 'link_libraries' in data:
        return data['link_libraries']
    return True


def run_setup(data: dict):
    if 'setup' in data:
        for cmd in data['setup']:
            os.system(cmd)


def evaluate_test(test_path: str, circom: str, debug: bool, libs_path: str, timeout: int):
    with open(test_path) as f:
        test_data = json.load(f)
    test_cwd = Path(test_path).parent
    if not check_link_libraries(test_data):
        libs_path = None
    cwd = os.getcwd()
    os.chdir(test_cwd)
    run_setup(test_data)
    os.chdir(cwd)
    for n, test in enumerate(test_data['tests']):
        main_circom_file = test_cwd.joinpath(test['main'])
        report = run_test(str(main_circom_file), circom, debug, str(test_cwd), libs_path, timeout)
        report.test_id = f"{test_data['id']}_{n}"
        yield report

def get_reports(tests, circom, debug, src, timeout):
    for test in tests:
        yield from evaluate_test(test, circom, debug, str(src.joinpath("tests/libs")), timeout)

@click.command()
@click.option('--src', help='Path where the benchmark is located.')
@click.option('--out', help='Location of the output report.')
@click.option('--circom', help="Optional path to circom binary", default=os.path.realpath("target/release/circom"))
@click.option('--debug', help="Print debug information", is_flag=True)
@click.option('--timeout', help="Timeout for stopping the compilation", default=600)
def main(src, out, circom, debug, timeout):
    src = Path(src)
    tests = glob.glob(str(src.joinpath(GLOB)), recursive=True)
    reports = get_reports(tests, circom, debug, src, timeout)

    with open(out, 'w') as out_csv:
        print('test_id,successful,error_class,message,file,line,column,run_time', file=out_csv)
        for report in reports:
            report = report.to_dict()
            if report['successful']:
                print(report['test_id'], report['successful'], '', '', '', '', '', report['run_time'],
                    sep=',', file=out_csv)
            else:
                if report['panicked']:
                    print(report['test_id'], report['successful'], report['error_class'],
                          f"\"{report['panicked']['message']}\"",
                          report['panicked']['file'], report['panicked']['line'], report['panicked']['column'],
                          report['run_time'], sep=',', file=out_csv)
                else:
                    print(report['test_id'], report['successful'], report['error_class'], '', '', '', '',
                          report['run_time'], sep=',', file=out_csv)
            out_csv.flush()


if __name__ == "__main__":
    main()
