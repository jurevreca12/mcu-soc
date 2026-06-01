#!/bin/bash
RV_DBG_PATH=$(bender path riscv-dbg)
REMOTE_BITBANG_PATH=${RV_DBG_PATH}/tb/remote_bitbang/
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${REMOTE_BITBANG_PATH} ./obj_dir/Vmcu_soc_jtag_tb &
echo "Running OpenOCD!"
sleep 2
/foss/tools/bin/openocd -f tb/rvj1_compliance_test.cfg
echo "This is the end"
