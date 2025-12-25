#!/usr/bin/env python
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def count_ones(n):
    """Helper function to count the number of set bits in an integer."""
    count = 0
    n = int(n)
    while n:
        count += n & 1
        n >>= 1
    return count

@cocotb.test()
async def run_test(dut):
    """Testbench for round robin arbiter with request queue."""
    dut._log.info("Starting test...")
    dut._log.info('Dut: ' + ', '.join(filter(lambda x: not x.startswith('_'), dir(dut))))

    # Initialize inputs
    dut.req.value = 0
    dut.clk.value = 0
    dut.rst_n.value = 0

    # Start clock
    Clock(dut.clk, 1, unit="us").start()

    # Wait for reset deassertion
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Test sequence
    request_sequences = [
        # (idx, request, ticks)
        (0, 0b0001, 4),
        (1, 0b0000, 1),
        (2, 0b1000, 3),
        (3, 0b0100, 3),
        (4, 0b0010, 3),
        (5, 0b0001, 3),
        (6, 0b0000, 1),
        (7, 0b1000, 2),
        (8, 0b1100, 2),
        (9, 0b1110, 2),
        (10, 0b1111, 2),
        (11, 0b0000, 4),
        (12, 0b0010, 2),
        (13, 0b0110, 2),
        (14, 0b0101, 3),
        (15, 0b0011, 3),
        (16, 0b0010, 2),
        (17, 0b0000, 4),
        (18, 0b1000, 2),
        (19, 0b0001, 2),
        (20, 0b0100, 4),
        (21, 0b0000, 4),
    ]

    for i, req, ticks in request_sequences:
        dut.dbg_idx.value = i
        dut.req.value = req
        await ClockCycles(dut.clk, ticks)
        assert count_ones(dut.grant.value) <= 1, f"Multiple grants detected for i={i}, req={req:04b}, grant={dut.grant.value:04b}"

    dut._log.info("Test completed.")