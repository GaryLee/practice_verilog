#!python
# coding: utf-8

from collections.abc import Sequence
from collections import namedtuple

import cocotb
from cocotb.clock import Clock
from cocotb.types import Logic, LogicArray
from cocotb.handle import LogicArrayObject, LogicObject
from cocotb.triggers import FallingEdge, RisingEdge, Edge, ClockCycles, Timer, Combine, First

import logging
from logging.handlers import SocketHandler

class AttrDict(dict):
    """A dictionary that allows attribute-style access. 
    Basic usage: 
        d = AttrDict(your_dict)
    """
    __slots__ = () 
    __getattr__ = dict.__getitem__
    __setattr__ = dict.__setitem__

class PicoSecond:
    def __rmatmul__(self, value):
        return Timer(value, units='ps')
    def __rmul__(self, value):
        return Timer(value, units='ps')

class NanoSecond:
    def __rmatmul__(self, value):
        return Timer(value, units='ns')
    def __rmul__(self, value):
        return Timer(value, units='ns')

class MicroSecond:
    def __rmatmul__(self, value):
        return Timer(value, units='us')
    def __rmul__(self, value):
        return Timer(value, units='us')

class MilliSecond:
    def __rmatmul__(self, value):
        return Timer(value, units='ms')
    def __rmul__(self, value):
        return Timer(value, units='ms')

class Falling:
    def __rmatmul__(self, value):
        return FallingEdge(value)
    def __rmul__(self, value):
        return FallingEdge(value)

class Rising:
    def __rmatmul__(self, value):
        return RisingEdge(value)
    def __rmul__(self, value):
        return RisingEdge(value)

class Edge:
    def __rmatmul__(self, value):
        return Edge(value)
    def __rmul__(self, value):
        return Edge(value)

class Cycles:
    def __init__(self, signal, rising=True):
        self.signal = signal
        self.rising = rising
    def __rmatmul__(self, value):
        return ClockCycles(self.signal, value, rising=self.rising)
    def __rmul__(self, value):
        return ClockCycles(self.signal, value, rising=self.rising)

ps = PicoSecond()
ns = NanoSecond()
us = MicroSecond()
ms = MilliSecond()

# Usage: await (clk@falling)
falling = Falling()
# Usage: await (clk@negedge)
negedge = Falling()
# Usage: await (clk@rising)
rising = Rising()
# Usage: await (clk@posedge)
posedge = Rising()
# Usage: await (clk@edge)
edge = Edge()
# Usage: await (10@cycles(clk))
cycles = Cycles
# Usage: await (combine(clk@posedge, 10@us))
combine = Combine
# Usage: await (first(clk@posedge, 10@us))
first = First

INT32_MIN = -2**31
INT32_MAX = 2**31-1

UINT32_MIN = 0
UINT32_MAX = 2**32-1

def flatten(x):
    """Flatten given parameter recursively."""
    if isinstance(x, Sequence):
        for v in x:
            yield from flatten(v)
    else:
        yield x

async def assign_value(dut_signal, *values, sync=None):
    """Assign values to a signal with optional synchronization."""
    assert sync is not None, "sync is required."
    for v in flatten(values):
        await (sync)
        dut_signal.value = v

async def until_match(signal, value=1, clk=None, timeout=None):
    """Wait for a signal to become a specific value. If clk is provided, wait for the signal to change on the rising edge of the clock."""
    timeout_clock_count = 0
    while signal.value != value:
        if clk is not None:
            await RisingEdge(clk)
            timeout_clock_count += 1
            if timeout and timeout_clock_count >= timeout:
                raise TimeoutError(f"Timeout waiting for signal {signal} to become {value}")
        else:
            await ReadOnly()  # Wait for a delta cycle

def period_ns(freq_hz):
    """Convert frequency to period in ns."""
    return int(1.0 / freq_hz * 1e9)

def period_ps(freq_hz):
    """Convert frequency to period in ps."""
    return int(1.0 / freq_hz * 1e12)
def logic_to_int(logic, signed=False, resolver='zeros'):
    """Convert Logic or LogicArray to integer."""
    assert isinstance(logic, (Logic, LogicObject, LogicArray, LogicArrayObject)), f"logic must be instance of Logic or LogicArray. {type(logic)=}."
    if isinstance(logic, (Logic, LogicObject)):
        return int(logic.value.resolve(resolver))

    if isinstance(logic, LogicArray):
        if signed:
            return logic.resolve(resolver).to_signed()
        else:
            return logic.resolve(resolver).to_unsigned()
         
    if signed:
        return logic.value.resolve(resolver).to_signed()
    return logic.value.resolve(resolver).to_unsigned()
    
def setup_clock(dut_signal, clk_freq_hz=None, clk_period_ns=None, start=True, soon=True):
    """Generate a clock with given frequency or period."""
    if clk_freq_hz is not None:
        clk_period_ns = period_ns(freq_hz=clk_freq_hz)
    assert isinstance(clk_period_ns, (int, float)), "Either clk_freq_hz or clk_period_ns must be provided."
    clk = Clock(dut_signal, int(clk_period_ns), unit='ns')
    if start:
        if soon:
            cocotb.start_soon(clk.start())
        else:
            clk.start()
    return clk

def setup_logging(ip='127.0.0.1', port=19996, supress_gpi_level=logging.ERROR):
    assert isinstance(ip, str), "ip must be a string."
    assert isinstance(port, int), "port must be an integer."
    logging.getLogger().addHandler(SocketHandler(ip, port))
    if supress_gpi_level is not None:
        logging.getLogger('gpi').setLevel(logging.ERROR) # Suppress GPI warnings.


def value_to_bytes(value, swap=False):
    """Convert a 32-bit integer value to a list of 4 bytes.

    Parameters
    ----------
    value: int
        The 32-bit integer value to convert.
    swap: bool
        If True, reverse the byte order.

    Returns
    -------
    list
        A list of 4 bytes representing the integer value.
    """
    bytes = [
        0xFF & (value >> 24),
        0xFF & (value >> 16),
        0xFF & (value >> 8),
        0xFF & (value),
    ]
    if swap:
        bytes.reverse()
    return bytes

def calc_bits(lsb, msb, byte_index):
    """Calculate the bit range within a specific byte for a given field.

    Parameters
    ----------
    lsb: int
        The least significant bit of the field.
    msb: int
        The most significant bit of the field.
    byte_index: int
        The index of the byte (0-3).

    Returns
    -------
    tuple
        A tuple (start_bit, end_bit) representing the bit range within the byte.
        Returns (None, None) if the field does not overlap with the byte.
    """
    brange = [(0, 7), (8, 15), (16, 23), (24, 31)]
    b0, b1 = brange[byte_index]
    if lsb > b1 or msb < b0:
        return None, None
    if b0 < lsb:
        b0 = lsb
    if b1 > msb:
        b1 = msb
    return (b0 % 8, b1 % 8)
