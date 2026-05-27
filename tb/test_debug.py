#!/usr/bin/python3
"""
Launches a testbench and openocd to test debug functionality.
Based on veri-run-openocd in riscv-dbg/tb
"""
import argparse
from subprocess import Popen, PIPE, STDOUT

def main(args):
    veri_proc = Popen(
        (args.test,),
        stdin=PIPE, stdout=PIPE, stderr=STDOUT,
        universal_newlines=True
    )

    for line in veri_proc.stdout:
        print(line, end='')
        if 'Listening on port' in line:
            print('Starting OpenOCD')
            break
        elif 'failed to bind socket' in line:
            print("Try 'killall testbench_verilator'", file=sys.stderr)
            exit(1)

    openocd_proc = Popen(
        (args.openocd, '-f', args.script),
        stdin=PIPE, stdout=PIPE, stderr=STDOUT,
        universal_newlines=True
    )
    print('Launched OpenOCD')

    ret = 1
    for line in openocd_proc.stdout:
        print(line, end='')
        if 'ALL TESTS PASSED' in line:
            ret=0

    if not openocd_proc.poll():
        openocd_proc.kill()
    if not veri_proc.poll():
        veri_proc.kill()
    exit(ret)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='test_debug',
        description='Runs simulation and openocd to test debug functionality.'
    )
    parser.add_argument('-t', '--test',
        help='The simulation binary.',
        type=str,
        default='./obj_dir/Vmcu_soc_jtag_tb'
    )
    parser.add_argument('-o', '--openocd',
        help='OpenOCD binary.',
        type=str,
        default='/foss/tools/bin/openocd'
    )
    parser.add_argument('-s', '--script',
        help='Script for OpenOCD.',
        type=str,
        default='dm_compliance_test.cfg'
    )
    args = parser.parse_args()
    print(f'Launching test_debug with arguments: {str(args)}')
    main(args)
