.PHONY: all pnr bitgen clean

SHELL=bash

FPGA_DB=/foss/tools/nextpnr-xilinx/xilinx/xc7a100t.bin

all: output/impl_netlist.edif pnr bitgen
pnr: output/mcu_soc.fasm
bitgen: output/mcu_soc.bit

mcu_soc.flist:
	bender script verilator -t xilinx -t rtl -t bscane &> mcu_soc.flist

#synth.flist: $(wildcard ../../*.{sv,v})
#	python create_flist.py

output:
	mkdir output

output/impl_netlist.edif: mcu_soc.flist output
	yosys -c synth.tcl -l output/yosys.log

output/mcu_soc.fasm: output/impl_netlist.json
	nextpnr-xilinx --freq 50 --json output/impl_netlist.json --chipdb $(FPGA_DB) --xdc constr_nexys.xdc --fasm output/mcu_soc.fasm --log output/nextpnr-xilinx.log --force

output/mcu_soc.frames: output/mcu_soc.fasm
	fasm2frames --part xc7a100tcsg324-1 \
		    --db-root /foss/tools/prjxray-db/artix7/ \
		    ./output/mcu_soc.fasm > output/mcu_soc.frames

output/mcu_soc.bit: output/mcu_soc.frames
	xc7frames2bit --part_file /foss/tools/prjxray-db/artix7/xc7a100tcsg324-1/part.yaml \
		      --part_name xc7a100tcsg324-1  \
		      --frm_file ./output/mcu_soc.frames \
		      --output_file ./output/mcu_soc.bit

clean:
	rm -rf output mcu_soc.flist
