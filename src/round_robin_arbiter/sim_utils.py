#!python
# coding: utf-8

from collections.abc import Sequence
from cocotb.triggers import FallingEdge, RisingEdge, Edge, ClockCycles, Timer, Combine, First

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
    assert sync is not None, "sync is required."
    for v in flatten(values):
        await (sync)
        dut_signal.value = v

def period_ns(freq_hz):
    """Convert frequency to period in ns."""
    return int(1.0 / freq_hz * 1e9)

def period_ps(freq_hz):
    """Convert frequency to period in ps."""
    return int(1.0 / freq_hz * 1e12)
