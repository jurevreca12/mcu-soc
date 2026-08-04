# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Authors:
# - Tim Fischer <fischeti@iis.ee.ethz.ch>

###############################################################################
# Setup
###############################################################################
set proj_name  [expr {[info exists ::env(PROJ_NAME)]  ? $::env(PROJ_NAME)  : "mcu-soc"}]
set top_design [expr {[info exists ::env(TOP_DESIGN)] ? $::env(TOP_DESIGN) : "mcu_soc"}]

set netlist "../yosys/out/${proj_name}_yosys.v"
set report_dir reports
set save_dir   save
set out_dir    out

file mkdir $report_dir
file mkdir $save_dir
file mkdir $out_dir

utl::report "Setting up project $proj_name"
utl::report " - Netlist: $netlist"
utl::report " - Netlist: $proj_name"
utl::report " - Top design: $top_design"
utl::report " - Report directory: $report_dir"
utl::report " - Save directory: $save_dir"
utl::report " - Output directory: $out_dir"
# Helper scripts
source scripts/reports.tcl
source scripts/checkpoint.tcl
source scripts/floorplan_util.tcl

# Initialize technology data (PDK libraries, LEFs, etc.)
source scripts/init_tech.tcl

# Set threads to 16 for all processes
set_thread_count 16


# CDL netlist
set cdl_netlist     "../openroad/out/${proj_name}.cdl"
set cdl_netlist_lvs "../openroad/out/${proj_name}_lvs.cdl"
set cdl_masters {}
set pdk_cells_lib ${pdk_dir}
lappend cdl_masters ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/cdl/sg13cmos5l_stdcell.cdl
lappend cdl_masters ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/cdl/sg13cmos5l_io.cdl
lappend cdl_masters ${pdk_dir}/ihp-sg13g2/libs.ref/sg13g2_sram/cdl/RM_IHPSG13_1P_1024x64_c2_bm_bist.cdl
