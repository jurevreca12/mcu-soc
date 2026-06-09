import os
import time
import cocotb
import subprocess
from forastero.io import IORole, io_suffix_style
from forastero.driver import DriverEvent
from forastero import BaseBench
from cocotb.triggers import ClockCycles, Timer, Join, Event
from base import get_test_runner, WAVES
from openocd import Client
from random import Random
from spi.io import SpiIO
from spi.requestor import SpiMisoDriver, SpiMonitor, SpiSSMonitor
from flash_memory.model import FlashMemoryModel
from test_mcu import get_flash_data
from subprocess import Popen, PIPE, STDOUT, DEVNULL
import shlex
from queue import Queue, Empty
from threading import Thread


TIMEOUT = 150000

OPENOCD = "/foss/tools/bin/openocd"
OPENOCD_SCRIPT = "/foss/designs/mcu-soc/tb/rvj1_debug.cfg"

class McuDbgTB(BaseBench):
    def __init__(self, dut):
        super().__init__(dut, clk=dut.clk, rst=dut.rstn, rst_active_high=False)
        spi_io = SpiIO(dut, "spi", IORole.INITIATOR, io_style=io_suffix_style)
        self.register("spi_monitor", SpiMonitor(self, spi_io, self.clk, self.rst))
        self.register("spi_ss_mon", SpiSSMonitor(self, spi_io, self.clk, self.rst))
        self.register("spi_miso_drv", SpiMisoDriver(self, spi_io, self.clk, self.rst))
        self.flash_mem = FlashMemoryModel(self.spi_monitor, self.spi_miso_drv, self.spi_ss_mon, Random(self.random.random()))

    async def initialise(self) -> None:
        await super().initialise()
        self.flash_mem.reset()


def stdout_reader(proc, queue):
    """Runs in a background thread."""
    for line in proc.stdout:
        queue.put(line)

    # Signal EOF
    queue.put(None)

async def start_openocd(dut):
    proc = Popen(
        shlex.split(f"{OPENOCD} -f {OPENOCD_SCRIPT}"),
        stdin=DEVNULL, stdout=PIPE, stderr=STDOUT, text=True
    )
    output_queue = Queue()
    t=Thread(
        target=stdout_reader,
        args=(proc, output_queue),
        daemon=True,
    ).start()
    connected = False
    while proc.poll() is None:
        # Drain all currently available lines
        while True:
            try:
                line = output_queue.get_nowait()
            except Empty:
                break

            if line is None:
                break
            dut._log.info(f"OPENOCD: {line.rstrip()}")
            if "Listening on port" in line:
                connected = True
        if connected:
            dut._log.info("OpenOCD is ready")
            break
        # Give simulation time to run
        await Timer(200, units="ns")
    else:
        dut._log.info(
            f"OpenOCD exited with code {proc.returncode}"
        )
    return 0


def openocd_cmdloop(oocd, cmd_queue):
    print("A4")
    while True:
        item = cmd_queue.get(block=True)
        print(f"Running command: {item['cmd']} with args: {item['args']}.")
        getattr(oocd, item['cmd'])(*item['args'])


@McuDbgTB.testcase(reset_wait_during=2, reset_wait_after=0, timeout=TIMEOUT, shutdown_delay=1, shutdown_loops=1)
async def halt_at_reset(tb:McuDbgTB, log):
    log.info(f"Test that the testbench is working")
    flash_data = get_flash_data("/foss/designs/mcu-soc/sw/bin/gpio.hex")
    tb.flash_mem.flash(flash_data)
    log.info(f"Launching OpenOCD!")
    task = cocotb.start_soon(start_openocd(tb.dut))
    await Join(task)

    print("A")
    with Client() as oocd:
        print("A1")
        cmd_queue = Queue()
        t=Thread(
            target=openocd_cmdloop,
            args=(oocd, cmd_queue),
            daemon=True,
        ).start()
        print("B")
        cmd_queue.put({'cmd': 'halt', 'args': []})
        #oocd.halt()
        print("C")
        registers = oocd.read_registers(['pc', 'sp'])
        print("D")
    log.info('Program counter: 0x%x' % registers['pc'])
    log.info('Stack pointer: 0x%x' % registers['sp'])
    oocd.resume()
    log.info("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx")
    await ClockCycles(tb.clk, TIMEOUT)


def test_mcu_dbg_runner():
    RV_DBG_PATH = subprocess.run(
        "bender path riscv-dbg",
        capture_output=True,
        shell=True
    ).stdout.decode('utf-8')[:-1] # Drop last char (newline)
    REMOTE_BITBANG_PATH=f"{RV_DBG_PATH}/tb/remote_bitbang"
    extra_args=[f'-GTIMEOUT={TIMEOUT+100}']
    extra_args+=[f'-LDFLAGS', f'-L{REMOTE_BITBANG_PATH} -Wl,--enable-new-dtags -Wl,-rpath,{REMOTE_BITBANG_PATH} -lrbs'] 
    extra_args+=[f'{RV_DBG_PATH}/tb/SimJTAG.sv']
    runner = get_test_runner("mcu_soc_jtag_tb", extra_args=extra_args)
    runner.test(hdl_toplevel="mcu_soc_jtag_tb", test_module="test_mcu_dbg", waves=WAVES)

if __name__ == "__main__":
    test_mcu_dbg_runner()
