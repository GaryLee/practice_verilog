# Define the default simulator (e.g., icarus, ghdl, questa, xcelium)
SIM ?= icarus

# SIM ?= verilator
# # Enable SystemVerilog
# VFLAGS += -sv

# Define the top-level language (verilog or vhdl)
TOPLEVEL_LANG ?= verilog

# Name of the top-level entity/module in your HDL design
TOPLEVEL = top

# Name of the Python module containing your test cases (without the .py extension)
COCOTB_TEST_MODULES = testbench

# Enable tracing (waveform generation)
WAVES = 1

# Specify your HDL source files
VERILOG_SOURCES = $(PWD)/top.sv $(PWD)/round_robin_arbiter.sv $(PWD)/request_queue.sv $(PWD)/round_robin_queue_arbiter.sv

# Include the main cocotb Makefile to handle build and simulation rules
include $(shell cocotb-config --makefiles)/Makefile.sim

# Optional: Add custom targets or configurations
clean::
	rm -rf sim_build
	rm -rf __pycache__
