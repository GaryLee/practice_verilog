#!python
# coding: utf-8

# Reference:
# https://docs.cocotb.org/en/stable/writing_testbenches.html

import cocotb
from cocotb import start_soon
from cocotb.clock import Clock
from cocotb.handle import Release, Force
from cocotb import utils

from sim_utils import *
from itertools import permutations

@cocotb.test()
async def {test_proc} (dut):
    # Generate clocks and initialization.
    clk_freq = 1e6
    clk_period_ns = int(1.0 / clk_freq * 1e9)
    cocotb.start_soon(Clock(dut.clk, period_ns(clk_period_ns), units="ns").start())

    # Show the information of DUT.
    dut._log.info(f"DUT: {{dut._name}}")
    dut.rst_n.value = 0
    dut.a.value = 0
    dut.b.value = 0
    await (dut.clk@posedge)
    dut.rst_n.value = 1
    await (dut.clk@posedge)
    for i, j in permutations(range(256), 2):
        dut.a.value = i
        dut.b.value = j
        await (2@cycles(dut.clk, rising=True))
        result = dut.c.value
        answer = (i + j) & 0xFF
        assert result == answer, f"Result mismatch: {{dut.a.value=}}, {{dut.b.value=}}, {{dut.c.value=}}"
        
    dut._log.info("TEST DONE!")