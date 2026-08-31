/*
Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original Author: Shay Gal-on
*/
#include "coremark.h"
#include "core_portme.h"

#define UART_CONFIG 0x60000000
#define UART_SPEED  0x60000004
#define UART_TX     0x60000008
#define UART_STATUS 0x6000000C

#define TIMER_BASE  0x30000000
#define TIMER_LOW   0x30000004
#define TIMER_HIGH  0x30000008

#define CLOCKS_PER_SEC 50000000

volatile ee_u32* uart_config = (ee_u32 *) (UART_CONFIG);
volatile ee_u32* uart_speed  = (ee_u32 *) (UART_SPEED);
volatile ee_u32* uart_tx     = (ee_u32 *) (UART_TX);
volatile ee_u32* uart_status = (ee_u32 *) (UART_STATUS);

volatile ee_u32* timer_low  = (ee_u32 *) (TIMER_LOW);
volatile ee_u32* timer_high = (ee_u32 *) (TIMER_HIGH);

void uart_print_string(const char* str);


#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

static ee_u64 read_mcycle(void)
{
    ee_u32 hi, lo;
    hi = *timer_high;
    lo = *timer_low;
    return ((ee_u64)hi << 32) | lo;
}


/* Porting : Timing functions
        How to capture time and convert to seconds must be ported to whatever is
   supported by the platform. e.g. Read value from on board RTC, read value from
   cpu clock cycles performance counter etc. Sample implementation for standard
   time.h and windows.h definitions included.
*/
CORETIMETYPE
barebones_clock()
{
    return (CORETIMETYPE)read_mcycle();
}
/* Define : TIMER_RES_DIVIDER
        Divider to trade off timer resolution and total time that can be
   measured.

        Use lower values to increase resolution, but make sure that overflow
   does not occur. If there are issues with the return value overflowing,
   increase this value.
        */
#define GETMYTIME(_t)              (*_t = barebones_clock())
#define MYTIMEDIFF(fin, ini)       ((fin) - (ini))
#define TIMER_RES_DIVIDER          1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC           (CLOCKS_PER_SEC / TIMER_RES_DIVIDER)

/** Define Host specific (POSIX), or target specific global time variables. */
static CORETIMETYPE start_time_val, stop_time_val;

/* Function : start_time
        This function will be called right before starting the timed portion of
   the benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or zeroing some system parameters - e.g. setting the cpu clocks
   cycles to 0.
*/
void
start_time(void)
{
    GETMYTIME(&start_time_val);
}
/* Function : stop_time
        This function will be called right after ending the timed portion of the
   benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or other system parameters - e.g. reading the current value of
   cpu cycles counter.
*/
void
stop_time(void)
{
    GETMYTIME(&stop_time_val);
}
/* Function : get_time
        Return an abstract "ticks" number that signifies time on the system.

        Actual value returned may be cpu cycles, milliseconds or any other
   value, as long as it can be converted to seconds by <time_in_secs>. This
   methodology is taken to accommodate any hardware or simulated platform. The
   sample implementation returns millisecs by default, and the resolution is
   controlled by <TIMER_RES_DIVIDER>
*/
CORE_TICKS
get_time(void)
{
    CORE_TICKS elapsed
        = (CORE_TICKS)(MYTIMEDIFF(stop_time_val, start_time_val));
    return elapsed;
}
/* Function : time_in_secs
        Convert the value returned by get_time to seconds.

        The <secs_ret> type is used to accommodate systems with no support for
   floating point. Default implementation implemented by the EE_TICKS_PER_SEC
   macro above.
*/
secs_ret
time_in_secs(CORE_TICKS ticks)
{
    secs_ret retval = ((secs_ret)ticks) / (secs_ret)EE_TICKS_PER_SEC;
    return retval;
}

ee_u32 default_num_contexts = 1;

/* Function : portable_init
        Target specific initialization code
        Test for some common mistakes.
*/
void
portable_init(core_portable *p, int *argc, char *argv[])
{
    p->portable_id = 1;
    *uart_config = 0x1;
    *uart_speed  = 5208;
    ee_printf("Starting CoreMark with %d iterations.", ITERATIONS);
}
/* Function : portable_fini
        Target specific final code
*/
void
portable_fini(core_portable *p)
{
    CORE_TICKS elapsed = get_time();
    ee_printf("CoreMark time elapsed: %d\n", elapsed);
    ee_printf("CoreMark ITERATIONS: %d\n", ITERATIONS);
    //ee_printf("Start time: %d\n", start_time_val);
    //ee_printf("Stop time: %d\n", stop_time_val);
    ee_u32 start_lo = (ee_u32)start_time_val;
    ee_u32 start_hi = (ee_u32)(start_time_val >> 32);
    ee_u32 stop_lo  = (ee_u32)stop_time_val;
    ee_u32 stop_hi  = (ee_u32)(stop_time_val >> 32);
    ee_printf("Start HI: %x LO: %x\n", start_hi, start_lo);
    ee_printf("Stop  HI: %x LO: %x\n", stop_hi, stop_lo);
    p->portable_id = 0;
}

void uart_send_char(char c) {
    while((*uart_status & 0x1) == 0) {
        // wait for uart to be ready
    }
    *uart_tx = (ee_u32) c;
}

void uart_print_string(const char* str) {
    while (*str) {
        uart_send_char(*str++);
    }
}

void trap_handler(void) {
    ee_u32 mcause, mepc, mtval, mstatus;
    __asm__ volatile ("csrr %0, mcause"  : "=r"(mcause));
    __asm__ volatile ("csrr %0, mepc"    : "=r"(mepc));
    __asm__ volatile ("csrr %0, mtval"   : "=r"(mtval));
    __asm__ volatile ("csrr %0, mstatus" : "=r"(mstatus));
    ee_printf("TRAP! mcause: 0x%x\r\nmepc: 0x%x\r\nmtval: 0x%x\r\nmstatus: 0x%x\r\n", mcause, mepc, mtval, mstatus);
    while(1) {
    }
}
