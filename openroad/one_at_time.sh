##############################
# Helper Functions (inline)
##############################

show_help() {
    cat << EOF
OpenROAD Backend Flow Script

Usage:
    ./run_backend.sh [OPTIONS]

Options:
    --help, -h          Show this help message
    --dry-run, -n       Only print commands instead of executing
    --verbose, -v       Print commands while executing
    --all               Run entire backend flow (stages 01-05)
    --floorplan         Stage 01: Initialize, floorplan, and power grid
    --placement         Stage 02: Repair netlist and placement
    --cts               Stage 03: Clock tree synthesis
    --routing           Stage 04: Global and detailed routing
    --finishing         Stage 05: Filler cells and output generation
    --run script        Run a script and exit (e.g., scripts/startup.tcl)
    --open script       Open GUI and execute script (e.g., scripts/startup.tcl)

Environment Variables:
    PROJ_NAME       - Project name (default: croc)
    TOP_DESIGN      - Top module name (default: croc_chip)

Examples:
    # Run entire backend flow
    ./run_backend.sh --all

    # Run only floorplan step
    ./run_backend.sh --floorplan

Inputs:
    - Synthesized netlist: yosys/${PROJ_NAME}_yosys.v
    - Constraints: openroad/src/constraints.sdc
    - PDK libraries: Auto-discovered from ${PDK_ROOT}

Outputs:
    - Checkpoints: openroad/save/*.zip
    - Reports: openroad/reports/
    - Final outputs: openroad/out/

EOF
    exit 0
}


run_cmd() {
    if [ "$DRYRUN" = 1 ]; then
        echo $1
    else
        eval $1
    fi
}

run_openroad_script() {
    run_cmd "echo [INFO][OpenROAD] Running $1"
    run_cmd "mkdir -p logs"
    logfile="logs/$(basename -s .tcl $1).log"
    run_cmd "openroad -exit $1 \
        -log $logfile \
        2>&1 | TZ=UTC gawk '{ print strftime(\"[%H:%M %Z]\"), \$0 }'"
}

open_openroad_script() {
    run_cmd "echo [INFO][OpenROAD] Open the GUI and run $1"
    run_cmd "mkdir -p logs"
    logfile="logs/$(basename -s .tcl $1).log"
    run_cmd "openroad -gui $1 \
        -log $logfile \
        2>&1 | TZ=UTC gawk '{ print strftime(\"[%H:%M %Z]\"), \$0 }'"
}

#run_openroad_script "scripts/init_tech.tcl"
run_openroad_script "scripts/XX_misc.tcl"
            shift