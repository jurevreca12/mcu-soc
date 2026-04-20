// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "config.h"

void sleep(void) {
    int i;
    for (i=0; i < SLEEP_CYCLES; i++);
}

int main() {
    uart_init();
    while (1) {
        printf("Hello World from RVJ1!\n");
        sleep();
        uart_write_flush();
    }
    return 0;
}