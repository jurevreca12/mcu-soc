// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Nils Wistoff <nwistoff@iis.ee.ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>

#pragma once

#define SLEEP_CYCLES        1000000

// Address map
#define BOOTROM_BASE_ADDR   0x80000000
#define UART_BASE_ADDR      0x60000000

// Frequencies
#define TB_FREQUENCY        100000000
#define TB_BAUDRATE         115200

// Peripheral configs
// UART
#define UART_BYTE_ALIGN     4
#define UART_FREQ           TB_FREQUENCY
#define UART_BAUD           TB_BAUDRATE
