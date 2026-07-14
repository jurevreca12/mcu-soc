.PHONY: all sim clean docker-build docker-run-it 

SHELL = bash

CUID := $(shell id -u)
CGID := $(shell id -g)
CWD  := $(abspath $(dir $$PWD))

BENDER     ?= bender
VERILATOR  ?= verilator
DOCKER_ADD_XILINX_PATH := $(if $(XILINX_DIR),-v $(XILINX_DIR):$(XILINX_DIR),)

VERILATOR_ARGS  = --timescale 1ns/1ps --binary -Wno-fatal -Wno-style
VERILATOR_ARGS += --trace-fst --trace-structs --trace-params -DRVFI
#VERILATOR_ARGS += -GINIT_FILE=\"/foss/designs/mcu-soc//sw/bin/gpio.hex\"

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SW_HEX_FILE := $(MAKEFILE_DIR)/sw/bin/hello_word.hex

RV_DBG_PATH := $(shell bender path riscv-dbg)
REMOTE_BITBANG_PATH := $(RV_DBG_PATH)/tb/remote_bitbang/

mcu_soc.f:
	$(BENDER) script verilator -t rtl &> mcu_soc.f

$(SW_HEX_FILE): sw/*.c sw/*.h sw/*.S sw/*.ld
	$(MAKE) -C sw/ compile	

obj_dir/Vmcu_soc_tb: mcu_soc.f $(SW_HEX_FILE)
	$(VERILATOR) $(VERILATOR_ARGS) --top mcu_soc_tb -f mcu_soc.f 
 
dump.fst: obj_dir/Vmcu_soc_tb
	./obj_dir/Vmcu_soc_tb

obj_dir/Vmcu_soc_jtag_tb: mcu_soc.f
	$(VERILATOR) $(VERILATOR_ARGS) \
		--top mcu_soc_jtag_tb \
		-f mcu_soc.f \
		-LDFLAGS "-L$(REMOTE_BITBANG_PATH) \
		-Wl,--enable-new-dtags -Wl,-rpath,remote_bitbang -lrbs" \
		$(RV_DBG_PATH)/tb/SimJTAG.sv 

dump_debug.fst: obj_dir/Vmcu_soc_jtag_tb
	./tb/debug.sh tb/rvj1_compliance_test.cfg

sim: dump.fst

all: sim

clean:
	rm -f mcu_soc.f
	rm -f trace.fst
	rm -rf obj_dir/
	$(MAKE) -C sw/ clean

docker-build:
	docker build -t iic-osic-tools-mcu-plus:0.1 .

docker-run-it:
	docker run -it \
			   --network host \
			   --user ${CUID}:${CGID} \
			   -e "UID=${CUID}" \
			   -e "GID=${CGID}" \
			   -v /etc/group:/etc/group:ro \
               -v /etc/passwd:/etc/passwd:ro \
               -v /etc/shadow:/etc/shadow:ro \
			   -v ~/.cache/:/headless/.cache:rw \
			   -v $(CWD):/foss/designs/mcu-soc \
				$(DOCKER_ADD_XILINX_PATH) iic-osic-tools-mcu-plus:0.1 -s /bin/bash
