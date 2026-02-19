from util import nios2_as, get_debug, require_symbols, hotpatch, get_regs
from csim import Nios2
import struct

# convert number to what we'd expect on hex display
def hexd(n):
    DIGIT = [0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67]
    n_digits = [int(x) for x in '%d'%n]     # individual digits
    n_bytes = list(map(lambda x: DIGIT[x], n_digits))   # map to 7seg values
    return struct.unpack('>I', bytes(n_bytes).rjust(4, b'\x00'))[0]       # combine into 32-bit value


def check_sw(asm, tests):
    obj = nios2_as(asm.encode('utf-8'))
    cpu = Nios2(obj=obj)


    class MMIO(object):
        def __init__(self):
            self.cur_sw = 0
            self.cur_hex = 0

        # MMIO interfaces
        def write_hex(self, val):
            self.cur_hex = val
        def write_hex_byte(self, val):
            # TODO
            print('Error: This CPU does not support word-unaligned MMIO (e.g. stbio unsupported')
            return
        def read_sw(self):
            return self.cur_sw

        def set_sw(self, n):
            self.cur_sw = n
        def get_hex(self):
            return self.cur_hex

    mmio = MMIO()

    # MMIO
    cpu.add_mmio(0xFF200040, mmio.read_sw)
    cpu.add_mmio(0xFF200020, mmio.write_hex)
    cpu.add_mmio(0xFF200021, mmio.write_hex_byte)
    cpu.add_mmio(0xFF200022, mmio.write_hex_byte)
    cpu.add_mmio(0xFF200023, mmio.write_hex_byte)

    passed = True

    for sw, expected in tests:
        mmio.set_sw(sw)
        
        # run a little bit...
        cpu.unhalt()
        instrs = cpu.run_until_halted(1000)
        if instrs < 1000:
            # cpu halted?
            print('Error: cpu halted after %d instructions' % instrs)

        val = mmio.get_hex()

        if val != expected:
            print(f'Error: set switches to {sw}, 7seg set to 0x{val:04x} (should be 0x{expected:04x})') 
            passed = False
            

    err = cpu.get_error()
    if err != '':
        #print(err)
        pass     #don't print error because we reach the instruction limit a bunch...
    del cpu

    if passed:
        print('Passed')



import sys

# tests is a list of switch positions to test, e.g. '5,3,12'
# we automatically check/convert with hexd()
tests = [(int(x),hexd(int(x))) for x in sys.argv[1].split(',')]
check_sw(sys.stdin.read(), tests)
 
