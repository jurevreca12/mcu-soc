# Copyright (c) 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Padring for mcu_chip (adapted from croc).
#
# Pad INSTANCE names below match mcu_chip.sv exactly. place_pad relocates the
# existing instances from the netlist; it does not create them. Synthesize
# mcu_chip as TOP_DESIGN so these pad_* instances exist.
#
# Pinout: 36 pads = 20 signal + 16 supply. Per edge:
#   [IO-supply pair] + signals + [core-supply pair]
#     WEST  (11): clock / reset / JTAG
#     SOUTH ( 9): GPIO inputs + UART tx
#     EAST  ( 9): GPIO outputs + SPI miso
#     NORTH ( 7): SPI master outputs
#
# Chip geometry (chipW/chipH, padD, padW, padBond) comes from floorplan.tcl.
# Min pad pitch for this PDK is ~90um: confirm each *Pitch below stays >= 90
# after the floorplan sets chipW/chipH, or pads overlap.

set cornerToPad [expr {$padBond + $padD}]

make_io_sites -horizontal_site sg13cmos5l_ioSite \
    -vertical_site sg13cmos5l_ioSite \
    -corner_site sg13cmos5l_ioSite \
    -offset $padBond \
    -rotation_horizontal R0 \
    -rotation_vertical R0 \
    -rotation_corner R0

##########################################################################
# Edge: LEFT / WEST (top to bottom) - clock, reset, JTAG                 #
##########################################################################
set westCount 11
set westSpan  [expr {$chipH - 2*$cornerToPad - $padW}]
set westPitch [expr {floor($westSpan / double($westCount - 1))}]
set westStart [expr {$chipH - $cornerToPad - $padW}]

place_pad -row IO_WEST -location [expr {$westStart -  0*$westPitch}] "pad_vssio0"        ; #  1
place_pad -row IO_WEST -location [expr {$westStart -  1*$westPitch}] "pad_vddio0"        ; #  2
place_pad -row IO_WEST -location [expr {$westStart -  2*$westPitch}] "pad_clk"           ; #  3
place_pad -row IO_WEST -location [expr {$westStart -  3*$westPitch}] "pad_rstn"          ; #  4
place_pad -row IO_WEST -location [expr {$westStart -  4*$westPitch}] "pad_jtag_tck_i"    ; #  5
place_pad -row IO_WEST -location [expr {$westStart -  5*$westPitch}] "pad_jtag_tdi_i"    ; #  6
place_pad -row IO_WEST -location [expr {$westStart -  6*$westPitch}] "pad_jtag_tdo_o"    ; #  7
place_pad -row IO_WEST -location [expr {$westStart -  7*$westPitch}] "pad_jtag_tms_i"    ; #  8
place_pad -row IO_WEST -location [expr {$westStart -  8*$westPitch}] "pad_jtag_trstn_i"  ; #  9
place_pad -row IO_WEST -location [expr {$westStart -  9*$westPitch}] "pad_vss0"          ; # 10
place_pad -row IO_WEST -location [expr {$westStart - 10*$westPitch}] "pad_vdd0"          ; # 11

##########################################################################
# Edge: BOTTOM / SOUTH (left to right) - GPIO inputs + UART              #
##########################################################################
set southCount 9
set southSpan  [expr {$chipW - 2*$cornerToPad - $padW}]
set southPitch [expr {floor($southSpan / double($southCount - 1))}]
set southStart $cornerToPad

place_pad -row IO_SOUTH -location [expr {$southStart + 0*$southPitch}] "pad_vssio1"      ; #  1
place_pad -row IO_SOUTH -location [expr {$southStart + 1*$southPitch}] "pad_vddio1"      ; #  2
place_pad -row IO_SOUTH -location [expr {$southStart + 2*$southPitch}] "pad_gpio_in_i_0" ; #  3
place_pad -row IO_SOUTH -location [expr {$southStart + 3*$southPitch}] "pad_gpio_in_i_1" ; #  4
place_pad -row IO_SOUTH -location [expr {$southStart + 4*$southPitch}] "pad_gpio_in_i_2" ; #  5
place_pad -row IO_SOUTH -location [expr {$southStart + 5*$southPitch}] "pad_gpio_in_i_3" ; #  6
place_pad -row IO_SOUTH -location [expr {$southStart + 6*$southPitch}] "pad_tx"          ; #  7
place_pad -row IO_SOUTH -location [expr {$southStart + 7*$southPitch}] "pad_vss1"        ; #  8
place_pad -row IO_SOUTH -location [expr {$southStart + 8*$southPitch}] "pad_vdd1"        ; #  9

##########################################################################
# Edge: RIGHT / EAST (bottom to top) - GPIO outputs + SPI miso           #
##########################################################################
set eastCount 9
set eastSpan  [expr {$chipH - 2*$cornerToPad - $padW}]
set eastPitch [expr {floor($eastSpan / double($eastCount - 1))}]
set eastStart $cornerToPad

place_pad -row IO_EAST -location [expr {$eastStart + 0*$eastPitch}] "pad_vssio2"          ; #  1
place_pad -row IO_EAST -location [expr {$eastStart + 1*$eastPitch}] "pad_vddio2"          ; #  2
place_pad -row IO_EAST -location [expr {$eastStart + 2*$eastPitch}] "pad_gpio_out_o_0"    ; #  3
place_pad -row IO_EAST -location [expr {$eastStart + 3*$eastPitch}] "pad_gpio_out_o_1"    ; #  4
place_pad -row IO_EAST -location [expr {$eastStart + 4*$eastPitch}] "pad_gpio_out_o_2"    ; #  5
place_pad -row IO_EAST -location [expr {$eastStart + 5*$eastPitch}] "pad_gpio_out_o_3"    ; #  6
place_pad -row IO_EAST -location [expr {$eastStart + 6*$eastPitch}] "pad_spi_miso_i"      ; #  7
place_pad -row IO_EAST -location [expr {$eastStart + 7*$eastPitch}] "pad_vss2"            ; #  8
place_pad -row IO_EAST -location [expr {$eastStart + 8*$eastPitch}] "pad_vdd2"            ; #  9

##########################################################################
# Edge: TOP / NORTH (right to left) - SPI master outputs                 #
##########################################################################
set northCount 7
set northSpan  [expr {$chipW - 2*$cornerToPad - $padW}]
set northPitch [expr {floor($northSpan / double($northCount - 1))}]
set northStart [expr {$chipW - $cornerToPad - $padW}]

place_pad -row IO_NORTH -location [expr {$northStart - 0*$northPitch}] "pad_vssio3"       ; #  1
place_pad -row IO_NORTH -location [expr {$northStart - 1*$northPitch}] "pad_vddio3"       ; #  2
place_pad -row IO_NORTH -location [expr {$northStart - 2*$northPitch}] "pad_spi_ss_o_0"   ; #  3
place_pad -row IO_NORTH -location [expr {$northStart - 3*$northPitch}] "pad_spi_sclk_o"   ; #  4
place_pad -row IO_NORTH -location [expr {$northStart - 4*$northPitch}] "pad_spi_mosi_o"   ; #  5
place_pad -row IO_NORTH -location [expr {$northStart - 5*$northPitch}] "pad_vss3"         ; #  6
place_pad -row IO_NORTH -location [expr {$northStart - 6*$northPitch}] "pad_vdd3"         ; #  7

# Fill in the rest of the padring
place_corners $iocorner

place_io_fill -row IO_NORTH {*}$iofill
place_io_fill -row IO_SOUTH {*}$iofill
place_io_fill -row IO_WEST  {*}$iofill
place_io_fill -row IO_EAST  {*}$iofill

# Connect built-in power rings
connect_by_abutment

# Bondpad as separate cell placed in OpenROAD:
puts "Bondpad cell: $bondPadCell"
place_bondpad -bond $bondPadCell -offset {5.0 -70.0} pad_*

# remove rows created by make_io_sites as they are no longer needed
remove_io_rows
