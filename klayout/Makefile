gds:
	./run_finishing.sh --gds --seal --fill

drc:
	python /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/run_drc.py \
		--path /foss/designs/mcu-soc/klayout/out/mcu-soc.filled.gds.gz \
		--run_dir /foss/designs/mcu-soc/klayout/drc/ \
		--drc_json /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/rule_decks/sg13cmos5l_tech_default.json \
		--run_mode deep

lvs:
	python /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/lvs/run_lvs.py \
		--layout=/foss/designs/mcu-soc/klayout/out/mcu-soc.gds.gz \
		--netlist=/foss/designs/mcu-soc/openroad/out/mcu-soc_lvs.cdl \
		--topcell=mcu_chip \
		--run_dir=/foss/designs/mcu-soc/klayout/lvs
