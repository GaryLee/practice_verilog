#!/bin/sh
# coding: utf-8

import sys
from invoke import task, Program, Collection

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

@task
def waveform(c):
    """Show waveform."""
    c.run("gtkwave sim_build/dut.fst")

if __name__ == "__main__":
    namespace = Collection.from_module(sys.modules[__name__])
    program = Program(namespace=namespace, version="0.1.0")
    program.run()