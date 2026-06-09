import os
import subprocess
import json
from pathlib import Path
from cocotb_tools.runner import get_runner

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()
WAVES = os.getenv("WAVES", default=False)
ASSERTIONS = os.getenv("ASSERTIONS", default=True)
RVFI = os.getenv("RVFI", default=True)

def get_rtl_files():
    rtl_files = []
    sources = subprocess.run(
        "bender sources -t rtl -t tech_cells_generic_exclude_deprecated --flatten", 
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
    sources = subprocess.run(
        "bender sources -t rtl -t tech_cells_generic_exclude_deprecated --flatten", 
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
    if WAVES:
        build_args += ["--trace-fst"]
    if ASSERTIONS:
        build_args += [f"-DASSERTIONS"]
    if RVFI:
        build_args += [f"-DRVFI"]
    build_args += extra_args
    runner = get_runner(sim)
    runner.build(
        sources=get_rtl_files(),
        includes=get_inc_dirs(),
        build_args=build_args,
        hdl_toplevel=hdl_top,
        always=True,
        waves=False,
    )
    return runner
