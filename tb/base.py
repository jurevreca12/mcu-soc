import os
import subprocess
import json
from pathlib import Path
from cocotb_tools.runner import get_runner

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()
WAVES = os.getenv("WAVES", default=False)
ASSERTIONS = os.getenv("ASSERTIONS", default=True)
RVFI = os.getenv("RVFI", default=True)
GATELEVEL = os.getenv("GATELEVEL", default=False)

def get_rtl_files():
    global GATELEVEL
    rtl_files = []
    if GATELEVEL:
        rtl_files = [
            "/foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v",
            "/foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_udp.v",
            "/foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/verilog/sg13cmos5l_io.v",
            "/foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_core_behavioral_bm_bist.v",
            "/foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_1024x64_c2_bm_bist.v",
            #"/foss/designs/mcu-soc/yosys/out/mcu-soc_yosys.v",
            #"/foss/designs/mcu-soc/openroad/out/mcu-soc_lvs.v",
            "/foss/designs/mcu-soc/yosys/out/netlist_debug.v",
            "/foss/designs/mcu-soc/tb/mcu_chip_tb.sv",
            "/foss/designs/mcu-soc/tb/mcu_chip_jtag_tb.sv",
            "/foss/designs/mcu-soc/.bender/git/checkouts/riscv-dbg-08557efb49681bce/tb/SimJTAG.sv",
        ]
        print("------------------------------------------------------")
        print("RUNNING GATELEVEL SIMULATION!")
        print("------------------------------------------------------")
    else:
        sources = subprocess.run(
            "bender sources --keep-excluded-incdirs -t rtl -t tech_cells_generic_exclude_deprecated --flatten", 
            capture_output=True, 
            shell=True
        )
        sources = json.loads(sources.stdout)
        for src_pkg in sources:
            for file in src_pkg['files']:
                rtl_files.append(Path(file))
    return rtl_files

def get_inc_dirs():
    inc_dirs = []
    if not GATELEVEL:
        sources = subprocess.run(
            "bender sources --keep-excluded-incdirs -t rtl -t tech_cells_generic_exclude_deprecated --flatten", 
            capture_output=True, 
            shell=True
        )
        sources = json.loads(sources.stdout)
        for src_pkg in sources:
            for pkg, files in src_pkg['export_incdirs'].items():
                for file in files:
                    inc_dirs.append(Path(file))
    return inc_dirs

def get_test_runner(hdl_top, extra_args=[]):
    sim = os.getenv("SIM", default="verilator")
    build_args = ["-Wno-fatal", "--no-stop-fail", "--timing"]
    if not GATELEVEL:
        sources_file = os.getenv("SOURCES_FILE", default="/foss/designs/mcu-soc/tb/sources.f")
        build_args += ["-f", sources_file]
    else:
        build_args += ['-Wno-ASSIGNIN']
    if WAVES:
        build_args += ["--trace-fst", "--trace-structs"]
    if ASSERTIONS:
        build_args += [f"-DASSERTIONS"]
    if RVFI:
        build_args += [f"-DRVFI"]
    build_args += extra_args
    if sim != "verilator":
        build_args = []
    runner = get_runner(sim)
    if GATELEVEL:
        runner.build(
            sources=get_rtl_files(),
            includes=get_inc_dirs(),
            build_args=build_args,
            hdl_toplevel=hdl_top,
            always=True,
            waves=False,
        )
    else:
        runner.build(
            build_args=build_args,
            hdl_toplevel=hdl_top,
            always=True,
            waves=False,
        )
    return runner
