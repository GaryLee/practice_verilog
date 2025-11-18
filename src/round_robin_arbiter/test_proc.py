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

def is_onehot_or_zero(n):
    if n == 0:
        return True
    return n & (n - 1) == 0

@cocotb.test()
async def test_proc(dut):
    # Show information of DUT.
    cocotb.log.info(f"NUM_CLIENTS: {dut.u_req_grant_fifo.NUM_CLIENTS.value}")
    # Generate clocks and initialization.
    clk_freq = 1e6
    clk_period_ns = int(1.0 / clk_freq * 1e9)
    cocotb.start_soon(Clock(dut.clk, period_ns(clk_period_ns), units="ns").start())

    # Show the information of DUT.
    dut._log.info(f"DUT: {dut._name}")
    dut.rst_n.value = 1
    await (2@cycles(dut.clk, rising=True))
    dut.rst_n.value = 0
    dut.req.value = 0
    await (2@cycles(dut.clk, rising=True))
    dut.rst_n.value = 1
    await (dut.clk@posedge)
    testcases = [
        0b0001,
        0b0011,
        0b0100,
        0b1100,
        0b0011,
        0b0110,
        0b1110,
        0b1111,
        0b0111,
        0b1011,
        0b1101,
        0b1111,
    ]
    for i, req in enumerate(testcases):
        dut.req.value = req
        dut._log.info(f"Round {i}: {req:04b}, {dut.grant.value.binstr}")
        await (2@cycles(dut.clk, rising=True))
        grant = dut.grant.value
        await (2@cycles(dut.clk, rising=True))
        if not grant.is_resolvable:
            dut.req.value = req
        else:
            dut.req.value = req & ~grant
        await (2@cycles(dut.clk, rising=True))
    dut._log.info("TEST DONE!")