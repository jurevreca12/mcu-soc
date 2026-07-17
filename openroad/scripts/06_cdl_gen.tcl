source scripts/startup.tcl

utl::report "Reading verilog  ${out_dir}/${proj_name}_lvs.v"
read_verilog ${out_dir}/${proj_name}_lvs.v
utl::report "Writing LVS CDL to ${cdl_netlist_lvs}"
write_cdl -include_fillers -masters $cdl_masters ${cdl_netlist_lvs}
