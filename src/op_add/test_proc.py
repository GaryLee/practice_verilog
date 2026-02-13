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
async def test_proc (dut):
    # Generate clocks and initialization.
    clk_freq = 1e6 # The clock frequency in Hz.
    cocotb.start_soon(Clock(dut.clk, period_ns(freq_hz=clk_freq), unit="ns").start())

    # Show the information of DUT.
    dut._log.info(f"DUT: {dut._name}")
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
        answer_sat = min(i + j, 255)
        assert result == answer_sat, f"Result mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, c={hex(dut.c.value)} != answer={hex(answer)}"
        
    dut._log.info("TEST DONE!")
