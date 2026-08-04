# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# instances.tcl for top module `mcu_chip`.
#
# Defines the hierarchical instance handles used by:
#   - floorplan.tcl  -> $bank0_sram0 (placeInstance)  [single SRAM macro]
#   - constraints.sdc -> $JTAG_ASYNC_{REQ,RSP}_{START,END} (currently unused)
#
# Sourced AFTER read_verilog + link_design so the cells exist.

utl::report "Resolving design instances for mcu_chip..."

##########################################################################
# Helper: warn (not abort) if a handle resolved to nothing
##########################################################################
proc check_handle {name val} {
    if {[llength $val] == 0} {
        utl::warn FLW 9001 "instances.tcl: '$name' resolved to 0 objects."
    } else {
        utl::report "  $name -> $val"
    }
}

##########################################################################
# Macro (SRAM) instances
##########################################################################
# mcu_soc maps its 4096-word memory onto ONE physical macro:
#   RM_IHPSG13_1P_2048x64_c2_bm_bist  (2048 x 64 = 16 KiB)
# Look it up by master (unambiguous) and store its full NAME string, which is
# what placeInstance expects.
#set _sram_cells [get_cells -hier -filter "ref_name == RM_IHPSG13_1P_2048x64_c2_bm_bist"]
#set _sram_cells [get_cells -hier -filter "ref_name == RM_IHPSG13_1P_512x64_c2_bm_bist"]
set _sram_cells [get_cells -hier -filter "ref_name == RM_IHPSG13_1P_1024x64_c2_bm_bist"]

if {[llength $_sram_cells] == 0} {
    #utl::warn FLW 9002 "No RM_IHPSG13_1P_2048x64 macro found - check the netlist/top."
    #utl::warn FLW 9002 "No RM_IHPSG13_1P_512x64 macro found - check the netlist/top."
    utl::warn FLW 9002 "No RM_IHPSG13_1P_1024x64 macro found - check the netlist/top."
    set bank0_sram0 ""
} else {
    set bank0_sram0 [get_full_name [lindex $_sram_cells 0]]
    if {[llength $_sram_cells] > 1} {
        utl::warn FLW 9003 "More than one SRAM macro found; using the first. \
Define additional bankN_sram0 handles and place them in floorplan.tcl."
    }
}
unset _sram_cells

check_handle bank0_sram0 $bank0_sram0

##########################################################################
# JTAG asynchronous CDC (riscv-dbg cdc_2phase) start/end points
##########################################################################
# The DMI 2-phase crossings are FLATTENED in this netlist (the cdc_2phase
# module boundary is dissolved; only the leaf registers async_req_o_reg,
# async_data_o[*]_reg, async_ack_o_reg remain, and they collide across the
# several crossings). A clean per-crossing -from/-to cannot be reconstructed.
#
# This is fine: set_clock_groups -asynchronous in constraints.sdc already makes
# these paths timing-safe. The per-crossing set_max_delay was only a
# metastability-margin optimization, and it stays COMMENTED in the SDC.
# Left empty on purpose (no check_handle -> no spurious warnings).

set MCU				i_mcu_soc
set JTAG			$MCU/dmi_jtag_inst
set JTAG_CDC_REQ		$JTAG/i_dmi_cdc.i_cdc_req
set JTAG_ASYNC_REQ_START	[get_fanin -to [get_nets $JTAG_CDC_REQ/*async_data*] -flat -startpoints_only -only_cells]
set JTAG_ASYNC_REQ_END [list]
set JTAG_ASYNC_REQ_CANDIDATES [get_fanout -from [get_nets $JTAG_CDC_REQ/*async*_data*] -flat -endpoints_only -only_cells]
foreach cell $JTAG_ASYNC_REQ_CANDIDATES {
	if {[string match "${JTAG_CDC_REQ}/*" [get_name $cell]]} {
		lappend JTAG_ASYNC_REQ_END $cell
	}
}
lappend JTAG_ASYNC_REQ_END {*}[get_fanout -from [get_pins $JTAG_CDC_REQ/*i_cdc_reset_ctrlr_half_a*async_data*_reg/Q] -flat -endpoints_only -only_cells]

set JTAG_CDC_RSP $JTAG/i_dmi_cdc.i_cdc_resp
set JTAG_ASYNC_RSP_START [get_fanin -to [get_nets $JTAG_CDC_RSP/*async_data*] -flat -startpoints_only -only_cells]
set JTAG_ASYNC_RSP_START [concat $JTAG_ASYNC_RSP_START [get_cells $JTAG_CDC_RSP/*async*_o*_reg]]
set JTAG_ASYNC_RSP_END [list]
set JTAG_ASYNC_RSP_CANDIDATES [get_fanout -from [get_nets $JTAG_CDC_RSP/*async*_data*] -flat -endpoints_only -only_cells]
foreach cell $JTAG_ASYNC_RSP_CANDIDATES {
	if {[string match "${JTAG_CDC_RSP}/*" [get_name $cell]]} {
		lappend JTAG_ASYNC_RSP_END $cell
	}
}
lappend JTAG_ASYNC_RSP_END {*}[get_fanout -from [get_pins $JTAG_CDC_RSP/*i_cdc_reset_ctrlr_half_a*async_data*_reg/Q] -flat -endpoints_only -only_cells]

#set JTAG_ASYNC_REQ_START {}
#set JTAG_ASYNC_REQ_END   {}
#set JTAG_ASYNC_RSP_START {}
#set JTAG_ASYNC_RSP_END   {}

utl::report "Instance resolution done."
