.PHONY: sim clean docker-build docker-run-it 

SHELL = bash

CUID := $(shell id -u)
CGID := $(shell id -g)
CWD  := $(abspath $(dir $$PWD))

BENDER    ?= bender
VERILATOR ?= verilator

VERILATOR_ARGS = --timescale 1ns/1ps --binary -Wno-fatal -Wno-style
VERILATOR_ARGS+= --trace-fst --trace-structs

SW_HEX_FILE := sw/bin/hello_world.hex

mcu_soc.f:
	$(BENDER) script verilator -t rtl &> mcu_soc.f

$(SW_HEX_FILE): sw/*.c sw/*.h sw/*.S sw/*.ld
	$(MAKE) -C sw/ compile	

sim: mcu_soc.f $(SW_HEX_FILE)
	$(VERILATOR) $(VERILATOR_ARGS) --top mcu_soc -f mcu_soc.f -DINIT_FILE=$(SW_HEX_FILE)
 
clean:
	rm mcu_soc.f
	rm trace.fst
	$(MAKE) -c sw/ clean

docker-build:
	docker build -t iic-osic-tools-plus:0.1 .

docker-run-it:
	docker run -it \
			   --user ${CUID}:${CGID} \
			   -e "UID=${CUID}" \
			   -e "GID=${CGID}" \
			   -v /etc/group:/etc/group:ro \
               -v /etc/passwd:/etc/passwd:ro \
               -v /etc/shadow:/etc/shadow:ro \
			   -v ~/.cache/:/headless/.cache:rw \
			   -v $(CWD):/foss/designs/mcu-soc \
			    iic-osic-tools-plus:0.1 -s /bin/bash
