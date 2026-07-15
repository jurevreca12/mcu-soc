# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Backend constraints for the CHIP-LEVEL top `mcu_chip`.
# Port names here are the package pins declared in mcu_chip.sv (per-bit scalar
# names like gpio_in_i_0, not the core's gpio_in_i[3:0] bus).
#
# Assumes mcu_chip.sv uses proper port directions (input/output for signal
# pads, inout only for supplies) so all_inputs/all_outputs classify correctly.

############
## Global ##
############
source src/instances.tcl


#############################
## Driving Cells and Loads ##
#############################
# Chip-level IO environment: model each input as being driven off-board by
# another IO output pad, and each output as driving ~2 receiver pads + trace.
set_load [expr 2 * 5.0 + 5.0] [all_outputs]
set_driving_cell [all_inputs] -lib_cell sg13cmos5l_IOPadOut16mA -pin pad


##################
## Input Clocks ##
##################
puts "Clocks..."
# Clocks enter through input pads (pad_clk, pad_jtag_tck_i). create_clock is
# placed on the chip port; the IO-cell delay is in the sg13cmos5l_io Liberty and
# is accounted for automatically in clock propagation.

# System clock: target 100 MHz
set TCK_SYS 10.0
create_clock -name clk_sys -period $TCK_SYS [get_ports clk]

# JTAG clock
set TCK_JTG 40.0
create_clock -name clk_jtg -period $TCK_JTG [get_ports jtag_tck_i]


##################################
## Clock Groups & Uncertainties ##
##################################
set_clock_groups -asynchronous -name clk_groups_async \
     -group {clk_jtg} \
     -group {clk_sys}

set_clock_uncertainty 0.1 [all_clocks]
set_clock_transition  0.2 [all_clocks]


####################
## Cdcs and Syncs ##
####################
puts "CDC/Sync..."
# The riscv-dbg DMI 2-phase crossings are flattened in the netlist; async clock
# groups above already make these paths timing-safe. The per-crossing max_delay
# is an optional metastability-margin goal. Keep commented unless instances.tcl
# resolves the JTAG_ASYNC_* handles (it warns if they are empty).
set_max_delay 3.0 -from $JTAG_ASYNC_REQ_START -to $JTAG_ASYNC_REQ_END -ignore_clock_latency
set_max_delay 3.0 -from $JTAG_ASYNC_RSP_START -to $JTAG_ASYNC_RSP_END -ignore_clock_latency


###########
## Reset ##
###########
puts "Reset..."
set_input_delay -max [ expr $TCK_JTG * 0.10 ] [get_ports {rstn}]
set_false_path -hold   -from [get_ports {rstn}]
set_max_delay $TCK_SYS -from [get_ports {rstn}]


##########
## JTAG ##
##########
puts "JTAG..."
set_input_delay  -min -add_delay -clock clk_jtg [ expr $TCK_JTG * 0.10 ] [get_ports {jtag_tdi_i jtag_tms_i}]
set_input_delay  -max -add_delay -clock clk_jtg [ expr $TCK_JTG * 0.30 ] [get_ports {jtag_tdi_i jtag_tms_i}]
set_output_delay -min -add_delay -clock clk_jtg [ expr $TCK_JTG * 0.10 ] [get_ports jtag_tdo_o]
set_output_delay -max -add_delay -clock clk_jtg [ expr $TCK_JTG * 0.20 ] [get_ports jtag_tdo_o]

set_input_delay -max [ expr $TCK_JTG * 0.10 ] [get_ports jtag_trstn_i]
set_false_path -hold    -from [get_ports jtag_trstn_i]
set_max_delay $TCK_JTG  -from [get_ports jtag_trstn_i]


##########
## GPIO ##
##########
puts "GPIO..."
# Split input/output buses; per-bit scalar port names -> wildcard match.
set_input_delay  -min -add_delay -clock clk_sys [ expr $TCK_SYS * 0.10 ] [get_ports {gpio_in_i_*}]
set_input_delay  -max -add_delay -clock clk_sys [ expr $TCK_SYS * 0.30 ] [get_ports {gpio_in_i_*}]

set_output_delay -min -add_delay -clock clk_sys [ expr $TCK_SYS * 0.10 ] [get_ports {gpio_out_o_*}]
set_output_delay -max -add_delay -clock clk_sys [ expr $TCK_SYS * 0.30 ] [get_ports {gpio_out_o_*}]


##########
## UART ##
##########
puts "UART..."
set_output_delay -min -add_delay -clock clk_sys [ expr $TCK_SYS * 0.10 ] [get_ports tx]
set_output_delay -max -add_delay -clock clk_sys [ expr $TCK_SYS * 0.30 ] [get_ports tx]


#########
## SPI ##
#########
puts "SPI..."
# Simple system-clock-relative constraints. If spi_sclk_o is a divided clock,
# prefer a generated clock on it (see template) and constrain mosi/ss/miso to it.
#
# set SPI_DIV 4
# create_generated_clock -name clk_spi -source [get_ports clk] \
#     -divide_by $SPI_DIV [get_ports spi_sclk_o]
#
set_output_delay -min -add_delay -clock clk_sys [ expr $TCK_SYS * 0.10 ] [get_ports {spi_ss_o_* spi_sclk_o spi_mosi_o}]
set_output_delay -max -add_delay -clock clk_sys [ expr $TCK_SYS * 0.30 ] [get_ports {spi_ss_o_* spi_sclk_o spi_mosi_o}]
set_input_delay  -min -add_delay -clock clk_sys [ expr $TCK_SYS * 0.10 ] [get_ports spi_miso_i]
set_input_delay  -max -add_delay -clock clk_sys [ expr $TCK_SYS * 0.30 ] [get_ports spi_miso_i]
