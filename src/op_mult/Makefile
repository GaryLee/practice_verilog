# Makefile

# Get the current working directory.
PWD=$(shell pwd)

# The source files to be tested.
# VERILOG_SOURCES = $(wildcard *.v) $(wildcard *.sv) $(wildcard *.vhdl)
VERILOG_SOURCES = $(wildcard *.v) $(wildcard *.sv) $(wildcard *.vhdl)

# The top module to be tested.
TOPLEVEL = dut

# The name of module for test.
MODULE = test_proc

# The compiler arguments. Define any macro for verilog.
COMPILE_ARGS = 

# Specify the top level language. Set it to verilog which support SystemVerilog as well.
TOPLEVEL_LANG = verilog

# Specify the simulator you want to use. 
SIM = icarus

# Any arguments or flags to pass to the execution of the compiled simulation.
SIM_ARGS = 

# Set WAVES to 1 to enable waveform dumping. A file with extension .fst will be created in the sim_build directory.
# Use GTKWave to view the waveform.
WAVES = 1

# Include the cocotb makefiles.
include $(shell cocotb-config --makefiles)/Makefile.sim
