# synth.tcl - synthesis script for yosys
# to run yosys synth.tcl
#
#yosys read_verilog -nooverwrite +/xilinx/cells_xtra.v
#yosys read_verilog +/xilinx/cells_sim.v
#yosys read_verilog src/ibuf.v
#yosys read_verilog src/bufg.v
#yosys read_verilog src/plle2_base.v
#yosys read_verilog -sv src/plle2_base_clkgen.sv

yosys plugin -i slang

yosys read_slang /foss/tools/yosys/share/yosys/xilinx/cells_xtra.v --top mcu_soc_xilinx -F mcu_soc.flist --allow-use-before-declare --blackboxed-module BSCANE2
#yosys read_slang src/plle2_basen.v --top rvj1_soc -F synth.flist
#yosys read_slang src/plle2_blackbox.sv src/rvj1_soc.sv -F synth.flist

yosys check


#-abc9 \

yosys synth_xilinx -top    mcu_soc_xilinx \
           -family xc7 \
           -dff \
           -nodsp \
	   -abc9 \
           -nowidelut \
           -edif ./output/impl_netlist.edif

yosys write_verilog ./output/impl_netlist.v
yosys write_blif    ./output/impl_netlist.blif
yosys write_json    ./output/impl_netlist.json
yosys stat -tech xilinx
