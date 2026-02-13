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

def add_unsigned(a, b, sat=False):
    a, b = a & 0xFF, b & 0xFF
    c = a + b
    ov = 1 if c > 0xFF else 0
    uv = 0
    c = 0xFF & (c if not sat else min(c, 0xFF))
    return c, ov, uv

def add_signed(a, b, sat=False):
    a_signed, b_signed = to_signed(a), to_signed(b)
    c = a_signed + b_signed
    ov = 1 if c > 127 else 0
    uv = 1 if c < -128 else 0
    c = 0xFF & (c if not sat else (min(max(c, -128), 127)))
    return c, ov, uv

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
        c_signed        = dut.c_signed.value.to_unsigned()
        ov_signed       = int(dut.ov_signed.value)
        uv_signed       = int(dut.uv_signed.value)
        c_unsigned      = dut.c_unsigned.value.to_unsigned()
        ov_unsigned     = int(dut.ov_unsigned.value)
        uv_unsigned     = int(dut.uv_unsigned.value)
        c_signed_sat    = dut.c_signed_sat.value.to_unsigned()
        ov_signed_sat   = int(dut.ov_signed_sat.value)
        uv_signed_sat   = int(dut.uv_signed_sat.value)
        c_unsigned_sat  = dut.c_unsigned_sat.value.to_unsigned()
        ov_unsigned_sat = int(dut.ov_unsigned_sat.value)
        uv_unsigned_sat = int(dut.uv_unsigned_sat.value)

        answer_unsigned, answer_ov_unsigned, answer_uv_unsigned = add_unsigned(i, j, sat=False)
        answer_unsigned_sat, answer_ov_unsigned_sat, answer_uv_unsigned_sat = add_unsigned(i, j, sat=True)
        answer_signed, answer_ov_signed, answer_uv_signed = add_signed(i, j, sat=False)
        answer_signed_sat, answer_ov_signed_sat, answer_uv_signed_sat = add_signed(i, j, sat=True)

        assert c_unsigned == answer_unsigned            , f"Unsigned result mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, c_unsigned({hex(c_unsigned)}) != answer_unsigned({hex(answer_unsigned)})"
        assert ov_unsigned == answer_ov_unsigned        , f"Unsigned overflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, ov_unsigned({ov_unsigned}) != answer_ov_unsigned({answer_ov_unsigned})"
        assert uv_unsigned == answer_uv_unsigned        , f"Unsigned underflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, uv_unsigned({uv_unsigned}) != answer_uv_unsigned({answer_uv_unsigned})"
        assert c_unsigned_sat == answer_unsigned_sat    , f"Unsigned sat result mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, c_unsigned_sat({hex(c_unsigned_sat)}) != answer_unsigned_sat({hex(answer_unsigned_sat)})"
        assert ov_unsigned_sat == answer_ov_unsigned_sat, f"Unsigned sat overflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, ov_unsigned_sat({ov_unsigned_sat}) != answer_ov_unsigned_sat({answer_ov_unsigned_sat})"
        assert uv_unsigned_sat == answer_uv_unsigned_sat, f"Unsigned sat underflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, uv_unsigned_sat({uv_unsigned_sat}) != answer_uv_unsigned_sat({answer_uv_unsigned_sat})"
        assert c_signed == answer_signed                , f"Signed result mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, c_signed({hex(c_signed)}) != answer_signed({hex(answer_signed)})"
        assert ov_signed == answer_ov_signed            , f"Signed overflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, answer={answer_signed}, ov_signed({ov_signed}) != answer_ov_signed({answer_ov_signed})"
        assert uv_signed == answer_uv_signed            , f"Signed underflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, uv_signed({uv_signed}) != answer_uv_signed({answer_uv_signed})"
        assert c_signed_sat == answer_signed_sat        , f"Signed sat result mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, c_signed_sat({hex(c_signed_sat)}) != answer_signed_sat({hex(answer_signed_sat)})"
        assert ov_signed_sat == answer_ov_signed_sat    , f"Signed sat overflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, ov_signed_sat({ov_signed_sat}) != answer_ov_signed_sat({answer_ov_signed_sat})"
        assert uv_signed_sat == answer_uv_signed_sat    , f"Signed sat underflow mismatch: a={hex(dut.a.value)}, b={hex(dut.b.value)}, uv_signed_sat({uv_signed_sat}) != answer_uv_signed_sat({answer_uv_signed_sat})"
        
    dut._log.info("TEST DONE!")
