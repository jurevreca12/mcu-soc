# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Authors:
# - Tobias Senti      <tsenti@ethz.ch>
# - Jannis Schönleber <janniss@iis.ee.ethz.ch>
# - Philippe Sauter   <phsauter@iis.ee.ethz.ch>

# Stage 04: Routing (Global Route + Detailed Route)
#
# This stage performs:
# - Global routing with congestion awareness
# - Incremental repair and re-routing
# - Antenna repair
# - Detailed routing
#
# Required environment variables:
#   PROJ_NAME    - Project name (e.g., "croc")
#   TOP_DESIGN   - Top module name
#
# Input checkpoint: 03_${PROJ_NAME}.cts
# Output checkpoint: 04_${PROJ_NAME}.routed

###############################################################################
# Setup
###############################################################################
source scripts/startup.tcl

# Load checkpoint from previous stage
load_checkpoint 03_${proj_name}.cts

# Set layers used for estimate_parasitics
setDefaultParasitics
set_dont_use $dont_use_cells


utl::report "###############################################################################"
utl::report "# Stage 04: ROUTING"
utl::report "###############################################################################"

utl::report "###############################################################################"
utl::report "# 04-01: Global Route"
utl::report "###############################################################################"

# Reduce TM1 to avoid too much routing there (bigger tracks -> bad for routing)
set_global_routing_layer_adjustment TopMetal1 0.20
set_routing_layers -signal Metal2-TopMetal1 -clock Metal2-TopMetal1

utl::report "Global route"
global_route -guide_file ${report_dir}/04_${proj_name}_route.guide \
    -congestion_report_file ${report_dir}/04_${proj_name}_route_congestionrpt \
    -allow_congestion
# Default params but -allow_congestion
# It continues even if it didn't find a solution (may be able to fix afterwards)

utl::report "Estimate parasitics"
estimate_parasitics -global_routing
report_metrics "04-01_${proj_name}.grt"
save_checkpoint 04-01_${proj_name}.grt
report_image "04-01_${proj_name}.grt" true false false true

grt::set_verbose 0

# Repair design using global route parasitics
utl::report "Perform buffer insertion before repairing setup and hold violations..."
repair_design -verbose

utl::report "Repair setup and hold violations..."
repair_timing -setup -verbose -repair_tns 100
#repair_timing -hold -hold_margin 0.1 -verbose -repair_tns 100
repair_timing -hold -hold_margin 0.25 -max_buffer_percent 40 -verbose -repair_tns 100

# Repair design using global route parasitics
utl::report "Perform buffer insertion after repairing setup and hold violations..."
repair_design -verbose

#utl::report "ECO: fixing max cap and slew on RAM inputs..."
#set sram_pins [get_pins i_mcu_soc.mem.mem.gen_1024x64xBx1.mem_inst/A_DIN[*]]
#
#foreach pin $sram_pins {
#	# Find net assigned to the pin
#	set current_net [get_nets -of_objects $pin]
#	# Find buffer driving the net
#	set driving_pin [get_pins -of_objects $current_net -filter "direction == output"]
#	set driving_cell [get_cells -of_objects $driving_pin]
#	set cell_type [get_property $driving_cell "name"]
#	# If using buf_1 or buf_2, force replace with buf_4
#	if {$cell_type == "sg13g2_buf_1" || $cell_type == "sg13g2_buf_2"} {
#		size_cell $driving_cell -lib_cell "sg13g2_buf_4"
#	}
#}
#
#legalize_placement

utl::report "GRT incremental..."
# Run to get modified net by DPL
global_route -start_incremental -allow_congestion

# Running DPL to fix overlapped instances
detailed_placement

# Route only the modified net by DPL
global_route -end_incremental \
            -guide_file ${report_dir}/04_${proj_name}_route.guide \
            -congestion_report_file ${report_dir}/04_${proj_name}_route_congestion.rpt \
            -allow_congestion \
            -verbose

estimate_parasitics -global_routing
report_metrics "04-01_${proj_name}.grt_repaired"
save_checkpoint 04-01_${proj_name}.grt_repaired
report_image "04-01_${proj_name}.grt_repaired" true true false true


utl::report "###############################################################################"
utl::report "# 04-02: Detailed Route"
utl::report "###############################################################################"

# Repair antennas (requires LEF cell with class 'CORE ANTENNACELL')
# ratio_margin: 30% safety margin on antenna ratios
repair_antennas -ratio_margin 30 -iterations 5

utl::report "Detailed route"
set_thread_count 8
detailed_route -output_drc ${report_dir}/04_${proj_name}_route_drc.rpt \
               -drc_report_iter_step 5 \
               -save_guide_updates \
               -clean_patches \
               -verbose 1

utl::report "Saving detailed route"
save_checkpoint 04_${proj_name}.routed
report_metrics "04_${proj_name}.routed"
report_image "04_${proj_name}.routed" true false false true

utl::report "###############################################################################"
utl::report "# Stage 04 complete: Checkpoint saved to ${save_dir}/04_${proj_name}.routed.zip"
utl::report "###############################################################################"
