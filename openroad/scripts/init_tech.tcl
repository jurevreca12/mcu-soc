# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Authors:
# - Tobias Senti      <tsenti@ethz.ch>
# - Jannis Schönleber <janniss@iis.ee.ethz.ch>
# - Philippe Sauter   <phsauter@iis.ee.ethz.ch>

# Initialize the PDK

utl::report "Init tech from Github PDK"
if {![info exists pdk_dir]} {
	set pdk_dir $env(PDK_ROOT)
}
set pdk_cells_lib ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lib
set pdk_cells_lef ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lef
set pdk_sram_lib  ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/lib
set pdk_sram_lef  ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/lef
set pdk_io_lib    ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/lib
set pdk_io_lef    ${pdk_dir}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/lef


if {![info exists mcu_dir]} {
	set mcu_dir $env(MCU_ROOT)
}
set pdk_pad_lef $mcu_dir/pdks/bondpad/lef
puts "PDK cells lib: $pdk_pad_lef"

define_corners tt ff

puts "Init standard cells"
read_liberty -corner tt ${pdk_cells_lib}/sg13cmos5l_stdcell_typ_1p20V_25C.lib
read_liberty -corner ff ${pdk_cells_lib}/sg13cmos5l_stdcell_fast_1p32V_m40C.lib

puts "Init IO cells"
read_liberty -corner tt ${pdk_io_lib}/sg13cmos5l_io_typ_1p2V_3p3V_25C.lib
read_liberty -corner ff ${pdk_io_lib}/sg13cmos5l_io_fast_1p32V_3p6V_m40C.lib

puts "Init SRAM macros"
foreach file [glob -directory $pdk_sram_lib *_typ_1p20V_25C.lib] {
	read_liberty -corner tt "$file"
}

foreach file [glob -directory $pdk_sram_lib *_fast_1p32V_m55C.lib] {
	read_liberty -corner ff "$file"
}

puts "Init tech-lef"
read_lef ${pdk_cells_lef}/sg13cmos5l_tech.lef

puts "Init cell-lef"
read_lef ${pdk_cells_lef}/sg13cmos5l_stdcell.lef
read_lef ${pdk_io_lef}/sg13cmos5l_io.lef
puts "Init pad-lef"
puts "reading files from $pdk_pad_lef"
read_lef ${pdk_pad_lef}/bondpad_70x70_5L.lef

foreach file [glob -directory $pdk_sram_lef RM_IHPSG13*.lef] {
	read_lef "$file"
}

# Set layers used for estimate_parasitics
proc setDefaultParasitics {} {
	set_wire_rc -clock -layer Metal3
	set_wire_rc -signal -layer Metal3
}

# Tie cell pins
set tieHiPin "sg13cmos5l_tiehi/L_HI"
set tieLoPin "sg13cmos5l_tielo/L_LO"

# Tap cell insertion
proc insertTapCells {} {
	# no tap cells in this PDK
}

set ctsBuf [ list sg13cmos5l_buf_16 sg13cmos5l_buf_8 sg13cmos5l_buf_4 sg13cmos5l_buf_2 ]
set ctsBufRoot sg13cmos5l_buf_8

# disallow OR from inserting these cells
set dont_use_cells [list sg13cmos5l_IOPad* ]

set stdfill [ list sg13cmos5l_fill_8 sg13cmos5l_fill_4 sg13cmos5l_fill_2 sg13cmos5l_fill_1 ]


set iocorner sg13cmos5l_Corner
set iofill [ list sg13cmos5l_Filler10000 sg13cmos5l_Filler4000 sg13cmos5l_Filler2000 sg13cmos5l_Filler1000 sg13cmos5l_Filler400 sg13cmos5l_Filler200 ]

set bondPadCell bondpad_70x70_5L
