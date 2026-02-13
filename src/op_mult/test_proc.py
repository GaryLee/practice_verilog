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

to_signed = lambda x: x if x < 128 else x - 256

def mult_unsigned(a, b, sat=False):
    a, b = a & 0xFF, b & 0xFF
    c = a * b
    ov = 1 if c > 0xFFFF else 0
    c = 0xFFFF & c
    if ov and sat:
        c = 32767
    return c, ov

def mult_signed(a, b, sat=False):
    a_signed, b_signed = to_signed(a), to_signed(b)
    c = a_signed * b_signed
    ov = 1 if c > 32767 or c < -32768 else 0
    if ov and sat:
        c = 32767 if c > 0 else -32768
    c = 0xFFFF & c
    return c, ov

@cocotb.test()
async def test_proc (dut):
    # Generate clocks and initialization.
    clk_freq = 1e6 # The clock frequency in Hz.
    clk_period_ns = int(1.0 / clk_freq * 1e9)
    cocotb.start_soon(Clock(dut.clk, period_ns(clk_period_ns), units="ns").start())

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
        c_signed        = dut.c_signed.value.to_unsigned()
        ov_signed       = int(dut.ov_signed.value)
        c_unsigned      = dut.c_unsigned.value.to_unsigned()
        ov_unsigned     = int(dut.ov_unsigned.value)
        c_signed_sat    = dut.c_signed_sat.value.to_unsigned()
        ov_signed_sat   = int(dut.ov_signed_sat.value)
        c_unsigned_sat  = dut.c_unsigned_sat.value.to_unsigned()
        ov_unsigned_sat = int(dut.ov_unsigned_sat.value)

        answer_unsigned, answer_ov_unsigned = mult_unsigned(i, j, sat=False)
        answer_unsigned_sat, answer_ov_unsigned_sat = mult_unsigned(i, j, sat=True)
        answer_signed, answer_ov_signed = mult_signed(i, j, sat=False)
        answer_signed_sat, answer_ov_signed_sat = mult_signed(i, j, sat=True)

        assert c_signed == answer_signed                , f"Signed multiplication failed for {i} * {j}: got {c_signed}, expected {answer_signed}"
        assert ov_signed == answer_ov_signed            , f"Signed multiplication overflow flag failed for {i} * {j}: got {ov_signed}, expected {answer_ov_signed}"
        assert c_unsigned == answer_unsigned            , f"Unsigned multiplication failed for {i} * {j}: got {c_unsigned}, expected {answer_unsigned}"
        assert ov_unsigned == answer_ov_unsigned        , f"Unsigned multiplication overflow flag failed for {i} * {j}: got {ov_unsigned}, expected {answer_ov_unsigned}"
        assert c_signed_sat == answer_signed_sat        , f"Signed multiplication with saturation failed for {i} * {j}: got {c_signed_sat}, expected {answer_signed_sat}"
        assert ov_signed_sat == answer_ov_signed_sat    , f"Signed multiplication with saturation overflow flag failed for {i} * {j}: got {ov_signed_sat}, expected {answer_ov_signed_sat}"
        assert c_unsigned_sat == answer_unsigned_sat    , f"Unsigned multiplication with saturation failed for {i} * {j}: got {c_unsigned_sat}, expected {answer_unsigned_sat}"
        assert ov_unsigned_sat == answer_ov_unsigned_sat, f"Unsigned multiplication with saturation overflow flag failed for {i} * {j}: got {ov_unsigned_sat}, expected {answer_ov_unsigned_sat}"
        
    dut._log.info("TEST DONE!")
