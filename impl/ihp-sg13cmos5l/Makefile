.PHONY: nextpnr clean yosys openroad

yosys:
	cd yosys && $(MAKE) yosys

floorplan: yosys
	cd openroad && $(MAKE) floorplan

placement: floorplan
	cd openroad && $(MAKE) placement

cts: placement
	cd openroad && $(MAKE) cts

routing: cts
	cd openroad && $(MAKE) routing

finishing: routing
	cd openroad && $(MAKE) finishing

cdl: finishing
	cd openroad && $(MAKE) cdl

openroad:
	cd openroad && $(MAKE) all

klayout:
	cd klayout && $(MAKE) gds

clean:
	rm *.jou -f
	rm *.log -f
	rm -rf ./vivado/output/ -f



