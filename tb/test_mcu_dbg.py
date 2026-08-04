import time
import subprocess
from forastero.io import IORole, io_suffix_style
from forastero import BaseBench
from cocotb.triggers import ClockCycles
from base import get_test_runner, WAVES, GATELEVEL
from random import Random
from spi.io import SpiIO
from spi.requestor import SpiMisoDriver, SpiMonitor, SpiSSMonitor
from flash_memory.model import FlashMemoryModel
from test_mcu import get_flash_data
from subprocess import Popen
import shlex
from multiprocessing import Process


TIMEOUT = 2000000

OPENOCD = "/foss/tools/bin/openocd"
OPENOCD_SCRIPT = "/foss/designs/mcu-soc/tb/rvj1_debug.cfg"

class McuDbgTB(BaseBench):
    def __init__(self, dut):
        super().__init__(dut, clk=dut.clk, rst=dut.rstn, rst_active_high=False)
        spi_io = SpiIO(dut, "spi", IORole.INITIATOR, io_style=io_suffix_style)
        self.register("spi_monitor", SpiMonitor(self, spi_io, self.clk, self.rst), scoreboard=False)
        self.register("spi_ss_mon", SpiSSMonitor(self, spi_io, self.clk, self.rst), scoreboard=False)
        self.register("spi_miso_drv", SpiMisoDriver(self, spi_io, self.clk, self.rst), scoreboard=False)
        self.flash_mem = FlashMemoryModel(self.spi_monitor, self.spi_miso_drv, self.spi_ss_mon, Random(self.random.random()))

    async def initialise(self) -> None:
        await super().initialise()
        self.flash_mem.reset()


    def openocd_proc(self):
        Popen(
            shlex.split(f"{OPENOCD} -f {OPENOCD_SCRIPT}"),
            universal_newlines=True
        )


@McuDbgTB.testcase(reset_wait_during=2, reset_wait_after=0, timeout=TIMEOUT, shutdown_delay=1, shutdown_loops=1)
async def halt_at_reset(tb:McuDbgTB, log):
    p = Process(target=tb.openocd_proc, args=())
    p.start()
    log.info(f"Test that the testbench is working")
    flash_data = get_flash_data("/foss/designs/mcu-soc/sw/bin/gpio.hex")
    tb.flash_mem.flash(flash_data)
    await ClockCycles(tb.clk, TIMEOUT)
    p.join(5)


def test_mcu_dbg_runner():
    RV_DBG_PATH = subprocess.run(
        "bender path riscv-dbg",
        capture_output=True,
        shell=True
    ).stdout.decode('utf-8')[:-1] # Drop last char (newline)
    REMOTE_BITBANG_PATH=f"{RV_DBG_PATH}/tb/remote_bitbang"
    tb_top = "mcu_chip_jtag_tb"
    extra_args=[f'-GTIMEOUT={TIMEOUT*2}']
    extra_args+=[f'-LDFLAGS', f'-L{REMOTE_BITBANG_PATH} -Wl,--enable-new-dtags -Wl,-rpath,{REMOTE_BITBANG_PATH} -lrbs'] 
    extra_args+=[f'{RV_DBG_PATH}/tb/SimJTAG.sv']
    runner = get_test_runner(tb_top, extra_args=extra_args)
    runner.test(
        hdl_toplevel=tb_top, 
        hdl_toplevel_lang='verilog', 
        test_module="test_mcu_dbg",
        #waves=WAVES
    )

if __name__ == "__main__":
    test_mcu_dbg_runner()
