# Cocotb Verification Template Environment 

## Requirement

To use this template, following softwares have to be installed properly.

- Icarus Verilog(https://github.com/steveicarus/iverilog): for compiling and simulation.
- Python(https://www.python.org/): for simulation and verification.
- Cocotb(https://www.cocotb.org/): for simulation and verification.

## Installation

- First install python(>= 3.10) to your system.
- Install pip3 if it doesn't come with Python.
- Install Icarus Verilog.
```bash
    > sudo apt install iverilog
```
- Install cocotb.
```bash
    > sudo pip3 install cocotb
```

- Install invoke(Optional)
```bash
    > sudo pip3 install invoke
```

## Prepare Makefile

A Makefile has been provided for verification. The variables in Makefile should be set properly before
verification.

- VERILOG_SOURCES: The source files of your design. They are .v or .sv files. Multiple files can be 
    seperated by white space.
- TOPLEVEL: The top module in your design.
- MODULE: The Python module file. The .py extension is omitted.
- COMPILE_ARGS: The arguments list here will be used when calling verilog compiler.
- TOPLEVEL_LANG: The language used in your design. Set it to verilog which support SystemVerilog as well.
- SIM: the simulator you want to use. We use icarus verilog. So, set it to icarus.
- WAVES: You can set this to 1 to output dump waveform. The dump waveform is in FST format which can be 
    loaded by Gtkwave.

## Prepare test bench.

Because we set the MODULE variable to test_proc here, you should have a Python file named test_proc.py
in the folder where Makefile exist. Check the test_proc.py for detail.

About the writing of test bench, read the document of cocotb for detail.

## Run the test bench

The execution of test bench is through make tool and Makefile. Use following command line to run the make file.

```bash
    > make -f Makefile results.xml 
```

We use make to process Makefile. By default, make will compile and execution the test bench. The
result will be exported to results.xml.

NOTE: make can't handle space character within path or file name. Avoid the usage of space character in
you design path and file.

## Use invoke to run tasks

Some common tasks are defined in tasks.py which provide a convenient interface to execute the task.

To list all tasks, 
```bash
    > python tasks.py --list
```

Run the test,
```bash
    > python tasks.py run
```
Show the waveform,
```bash
    > python tasks.py waveform
```