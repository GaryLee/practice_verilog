#!/bin/sh
# coding: utf-8

import sys
from invoke import task, Program, Collection

def which(program):
    """Check if a program exists in PATH."""
    import os
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None

@task
def clean(c):
    """Clean the project."""
    c.run("rm -f results.xml")
    c.run("make -f Makefile clean")

@task
def run(c):
    """Run the test."""
    c.run("rm -f results.xml")
    c.run("make -f Makefile results.xml")

@task(help={"args": "Additional arguments for waveform viewer"})
def waveform(c, args=""):
    """Show waveform."""
    tools = {
        'surfer': '{fst_file}',
        'gtkwave': '{fst_file}',
    }
    found_tools = [k for k in tools.keys() if which(k)]
    if not found_tools:
        print("No waveform viewer found (tried: " + ", ".join(tools.keys()) + ")")
        return
    cmd = found_tools[0]
    tool_args = tools[cmd].format(fst_file='sim_build/dut.fst')
    cmd_line = ' '.join([cmd, tool_args, args])
    c.run(cmd_line)

if __name__ == "__main__":
    namespace = Collection.from_module(sys.modules[__name__])
    program = Program(namespace=namespace, version="0.1.0")
    program.run()