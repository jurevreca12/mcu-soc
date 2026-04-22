.PHONY: all debug program sim clean

SHELL = bash
REPORTS = ./output/post_synth_power.rpt \
		  ./output/post_synth.dcp \
		  ./output/post_synth_clock_interaction.rpt \
		  ./output/post_synth_high_fanout_nets.rpt
NETLISTS = ./output/impl_netlist.v ./output/impl_netlist.edif
BITFILES = ./output/impl.bin ./output/impl.bit

SVFILES   = $(shell find -name "*.sv" -exec basename \{} \;)
SDBFILESX = $(SVFILES:%=./xsim.dir/work/%)
SDBFILES  = $(SDBFILESX:.sv=.sdb)
MODULES   = $(SVFILES:.sv=)

all: ./output/impl.bit
sim: ./output/tb.vcd

./output/:
	mkdir output

sources_vivado.tcl:
	bender script vivado -t rtl -t xilinx &> sources_vivado.tcl

$(REPORTS) $(NETLISTS) $(BITFILES): $(SVFILES) synth.tcl constr_nexys.xdc ./output/ sources_vivado.tcl
	vivado -mode batch -source synth.tcl -log ./output/vivado.log -nojournal

program: 
	vivado -mode batch -source prog.tcl

clean:
	rm -rf output/
	rm -f clockInfo.txt xvlog*.log xvlog*.pb
	rm -f xsim*.jou vivado*.log vivado*.jou
	rm sources_vivado.tcl
