#!/bin/bash
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>
# - Thomas Benz     <tbenz@iis.ee.ethz.ch>
#
# Environment setup for Croc SoC ASIC flow
# This file is sourced by all scripts to set up tool paths and PDK location

# Determine repository root

#export PDK_ROOT="$env(PDK_ROOT)"

if [[ -n "${BASH_SOURCE[0]}" ]]; then
    export MCU_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
else
    export MCU_ROOT=$(pwd)
fi
echo "[INFO][ENV] MCU root: $MCU_ROOT"


######################
# Project Settings
######################
export PROJ_NAME="${PROJ_NAME:-mcu-soc}"
export DUT_DESIGN="${DUT_DESIGN:-mcu_soc}"
#export PDK_ROOT="$MCU_ROOT/pdks/ihp13/pdk/"
export KLAYOUT_PATH="$PDK_ROOT/ihp-sg13cmos5l/libs.tech/klayout"
export PDK_DIR_LEF_TECH="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lef"
export PDK_DIR_LEF_CELLS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lef"
export PDK_DIR_LEF_SRAMS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/lef"
export PDK_DIR_LEF_IOS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/lef"
export PDK_DIR_LEF_BOND="$MCU_ROOT/pdks/bondpad/lef"
export PDK_DIR_GDS_CELLS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/gds"
export PDK_DIR_GDS_SRAMS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/gds"
export PDK_DIR_GDS_IOS="$PDK_ROOT/ihp-sg13cmos5l/libs.ref/sg13cmos5l_io/gds"
export PDK_DIR_GDS_BOND="$MCU_ROOT/pdks/bondpad/gds"
export PDKPATH="$MCU_ROOT/pdks/ihp13/ihp-sg13cmos5l/"


export TOP_DESIGN="${TOP_DESIGN:-mcu_chip}"
echo "[INFO][ENV] PDK root: $PDK_ROOT"
echo "[INFO][ENV] PDK files: $PDKPATH"
echo "[INFO][ENV] TOP_DESIGN: $TOP_DESIGN"
