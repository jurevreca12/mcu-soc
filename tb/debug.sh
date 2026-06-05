#!/bin/bash
OPENOCD_SCRIPT=$1
RV_DBG_PATH=$(bender path riscv-dbg)
REMOTE_BITBANG_PATH=${RV_DBG_PATH}/tb/remote_bitbang/
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${REMOTE_BITBANG_PATH} ./obj_dir/Vmcu_soc_jtag_tb &
echo "Running OpenOCD!"
sleep 2
/foss/tools/bin/openocd -f ${OPENOCD_SCRIPT}
echo "This is the end of debug.sh"
