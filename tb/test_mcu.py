from forastero.io import IORole, io_suffix_style
from forastero.driver import DriverEvent
from forastero import BaseBench
from cocotb.triggers import ClockCycles

from random import Random
from spi.io import SpiIO
from spi.requestor import SpiMisoDriver, SpiMonitor, SpiSSMonitor
from flash_memory.model import FlashMemoryModel

TX_DATA_REG_ADDR = 0
RX_DATA_REG_ADDR = 4
SPI_DIV_CLK_REG_ADDR = 8
SS_REG_ADDR = 12
CTRL_REG_ADDR = 16

TIMEOUT = 5000000


def jtag_tick(dut):
    dut.jtag_tck_i.value = 0
    dut.jtag_tms_i.value = 0
    dut.jtag_tdi_i.value = 0
    dut.jtag_trstn_i.value = 1

class McuTB(BaseBench):
    def __init__(self, dut):
        super().__init__(dut, clk=dut.clk, clk_drive=True, rst=dut.rstn, rst_active_high=False)
        spi_io = SpiIO(dut, "spi", IORole.INITIATOR, io_style=io_suffix_style)
        self.register("spi_monitor", SpiMonitor(self, spi_io, self.clk, self.rst))
        self.register("spi_ss_mon", SpiSSMonitor(self, spi_io, self.clk, self.rst))
        self.register("spi_miso_drv", SpiMisoDriver(self, spi_io, self.clk, self.rst))
        self.flash_mem = FlashMemoryModel(self.spi_monitor, self.spi_miso_drv, self.spi_ss_mon, Random(self.random.random()))
        #self.register("jtag", jtag_tick(dut))

    async def initialise(self) -> None:
        await super().initialise()
        self.flash_mem.reset()

def get_flash_data(path) -> list[int]:
    with open(path, 'r') as f:
        hex_data = f.read()
    hex_data = hex_data.split()
    num_bytes = len(hex_data) * 4
    first_word = format(num_bytes, '08X')
    hex_data.insert(0, first_word)
    mem=[]
    for word in hex_data:
        mem.append(int(word[6:8], 16))
        mem.append(int(word[4:6], 16))
        mem.append(int(word[2:4], 16))
        mem.append(int(word[0:2], 16))
    return mem

@McuTB.testcase(
    reset_wait_during=10, 
    reset_wait_after=0, 
    timeout=TIMEOUT, 
    shutdown_delay=1, 
    shutdown_loops=1
)
async def smoke(tb:McuTB, log):
    log.info(f"Test that the testbench is working")
    flash_data = get_flash_data("/workspaces/mcu-soc/sw/bin/gpio.hex")
    tb.flash_mem.flash(flash_data)
    await ClockCycles(tb.clk, TIMEOUT)


def test_mcu_runner(mcu_soc_test_fixture):
    #if GATELEVEL:
    #    tb_top = "mcu_chip_tb"
    #    extra_args=[f"-PTIMEOUT={TIMEOUT+100}"]
    #else:
    tb_top = "mcu_soc"
    extra_args=[f"-GTIMEOUT={TIMEOUT}"]
    mcu_soc_test_fixture.test(
        toplevel=tb_top,
        test_module="test_mcu",
        plusargs=extra_args,
        env={}
    )

