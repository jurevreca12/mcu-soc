# synth.tcl is a synthesis script for Vivado
# 
# run "vivado -mode batch -source synth.tcl" to get a compiled vivado design
#
# Nexys board
set_part xc7a100tcsg324-1

set script_path [ file dirname [ file normalize [ info script ] ] ]
set project_root_dir $script_path/../../.
set source_dir $project_root_dir/rtl
set output_dir $script_path/output/.

source ${script_path}/add_sources.tcl
read_xdc $script_path/constr_nexys.xdc

# Run synthesis
synth_design -top mcu_soc_xilinx -include_dirs $source_dir/inc
report_timing_summary    -file ${output_dir}/post_synth_timing_summary.rpt
report_power             -file ${output_dir}/post_synth_power.rpt
report_clock_interaction -file ${output_dir}/post_synth_clock_interaction.rpt -delay_type min_max
report_high_fanout_nets	 -file ${output_dir}/post_synth_high_fanout_nets.rpt -fanout_greater_than 200 -max_nets 5
write_verilog -force ${output_dir}/impl_netlist.v
write_edif    -force ${output_dir}/impl_netlist.edif

opt_design
place_design
route_design

write_bitstream -force ${output_dir}/impl.bit -bin_file
