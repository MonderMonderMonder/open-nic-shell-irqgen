import cocotb
import logging 
import random
from os import urandom
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

AXIL_ACLK_PERIOD_NS = 8  # freq = 125 mHz

GIRQ_CTRL_ADDR = 0x00
GIRQ_TRIG_ADDR = 0x04
GIRQ_STAT_ADDR = 0x08
GIRQ_CMPT_ADDR = 0x0c
GIRQ_TS0_ADDR  = 0x10
GIRQ_TS1_ADDR  = 0x14
GIRQ_TS2_ADDR  = 0x18

class TB:
    def __init__(self, dut):
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        
        self.dut = dut
        self.log.info("Got DUT: {}".format(dut))

        cocotb.start_soon(Clock(dut.axil_aclk, AXIL_ACLK_PERIOD_NS, units="ns").start())

        # cocotb by default assumes reset signals are active high, while open nic shell has reset signals active low. 
        # This is why we pass reset_active_level=False.
        self.axi_lite_if = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil_girq"), dut.axil_aclk, dut.axil_aresetn, reset_active_level=False)

    async def reset(self):
        self.dut.axil_aresetn.setimmediatevalue(1)
        # mod rst signals are synced with the axi_aclk
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 0
        self.dut.usr_irq_out_fail.value = 0
        self.dut.usr_irq_out_ack.value = 0
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 1
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)

    async def read_reg(self, address, bytes=False):
        val = await self.axi_lite_if.read(address, 4)
        return val.data if bytes else int.from_bytes(val.data, "little")
    
    async def write_reg(self, address, data):
        await self.axi_lite_if.write(address, data.to_bytes(4, "little"))
    
    async def qdma_ack_fail(self, after, ack=True):
        for _ in range(after):
            await RisingEdge(self.dut.axil_aclk)
        if ack:
            self.dut.usr_irq_out_ack.value = 1
            self.log.info("QDMA asserted usr_irq_out_ack")
        else:
            self.dut.usr_irq_out_fail.value = 1
            self.log.info("QDMA asserted usr_irq_out_fail")
        await RisingEdge(self.dut.axil_aclk)

async def axil_rw_test(tb: TB):
    addr = GIRQ_CTRL_ADDR
    written = random.randint(0, 0xFFFFF)
    await tb.write_reg(addr, written)
    read = await tb.read_reg(addr)

    assert read == written, f"Read register value mismatch: expected 0x{written:08X}, got 0x{read:08X}"
    tb.log.info(f"AXI Lite write and read successful: 0x{read:08X}")

async def girq_test(tb: TB):
    ctrl = random.randint(0, 0xFFFFF)
    vec = ctrl & 0x00FFF
    fnc = (ctrl & 0xFF000) >> 12
    await tb.write_reg(GIRQ_CTRL_ADDR, ctrl)
    await tb.write_reg(GIRQ_TRIG_ADDR, 1)
    
    assert tb.dut.usr_irq_in_vec.value.integer == vec, f"Expected usr_irq_in_vec value 0x{vec:03X}, got 0x{tb.dut.usr_irq_in_vec.value.integer:03X}"
    assert tb.dut.usr_irq_in_fnc.value.integer == fnc, f"Expected usr_irq_in_fnc value 0x{fnc:02X}, got 0x{tb.dut.usr_irq_in_fnc.value.integer:02X}"
    assert tb.dut.usr_irq_in_vld.value.integer == 1, f"Expected usr_irq_in_vld value 0x1, got 0x{tb.dut.usr_irq_in_vld.value.integer:01X}"
    trig = await tb.read_reg(GIRQ_TRIG_ADDR)
    assert trig == 0, f"Expected reg_girq_trig value 0x0, got 0x{trig:08X}"

    qdma_cycles = random.randint(2, 10)
    qdma_ack = random.choice([True, False])
    tb.log.info(f"Simulating the QDMA asserting " + ("usr_irq_out_ack" if qdma_ack else "usr_irq_out_fail") + " after {qdma_cycles} clock cycles @125 mHz ...")
    await tb.qdma_ack_fail(qdma_cycles, qdma_ack)

    await RisingEdge(tb.dut.axil_aclk) # due to internal reg_usr_irq_in_vld 
    assert tb.dut.usr_irq_in_vld.value.integer == 0, f"Expected usr_irq_in_vld value 0x0, got 0x{tb.dut.usr_irq_in_vld.value.integer:01X}" # adjust formatting

    stat = await tb.read_reg(GIRQ_STAT_ADDR)
    recv = stat & 0b001
    ack = (stat & 0b010) >> 1
    fail = (stat & 0b100) >> 2
    assert recv == 0, f"Expected recv value 0x0, got 0x{recv}"
    assert ack == (1 if qdma_ack else 0), f"Expected ack value 0x{1 if qdma_ack else 0}, got 0x{ack}"
    assert fail == (0 if qdma_ack else 1), f"Expected recv value 0x{0 if qdma_ack else 1}, got 0x{recv}"

# TODO test two irqs with same vec and fnc?

async def ts_test(tb: TB):
    ctrl = random.randint(0, 0xFFFFF)
    vec = ctrl & 0x00FFF
    fnc = (ctrl & 0xFF000) >> 12
    await tb.write_reg(GIRQ_CTRL_ADDR, ctrl)
    
    await tb.write_reg(GIRQ_TRIG_ADDR, 1) #1

    # cmpt = await tb.read_reg(GIRQ_CMPT_ADDR)
    # assert cmpt == 0, f"Expected reg_girq_cmpt value 0x0, got 0x{cmpt:08X}"

    await tb.qdma_ack_fail(3, True)

    random_cycles = 4
    for _ in range(random_cycles):
        await RisingEdge(tb.dut.axil_aclk)
    # await tb.write_reg(GIRQ_CTRL_ADDR, 1)
    await tb.write_reg(GIRQ_CMPT_ADDR, 1) #2

    ts1 = await tb.read_reg(GIRQ_TS0_ADDR)
    ts1 = await tb.read_reg(GIRQ_TS1_ADDR)
    ts2 = await tb.read_reg(GIRQ_TS2_ADDR)
    # assert ts2-ts1 == 0, f"Expected clock cycle difference between ts1 and ts2 to be 0x{0:08X}, got 0x{ts2:08X}"
    
    await tb.write_reg(GIRQ_TRIG_ADDR, 1)
    await RisingEdge(tb.dut.axil_aclk)
    # assert cmpt == 0, f"Expected reg_girq_cmpt value 0x0, got 0x{cmpt:08X}"
    

async def run_test(dut, idle_inserter=None, backpressure_inserter=None):
    
    tb = TB(dut)
    
    await tb.reset()
    await axil_rw_test(tb)

    await tb.reset()
    await girq_test(tb)
    
    await tb.reset()
    await ts_test(tb)

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.generate_tests()
