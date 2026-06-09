from random import Random

#from cocotb.log import SimLog
from forastero import MonitorEvent, DriverEvent

from spi.requestor import SpiMisoDriver, SpiMonitor, SpiSSMonitor
from spi.transaction import SpiTrans, SpiResetTrans
from enum import Enum

class State(Enum):
    IDLE = 1
    READ_ID = 2
    READ = 3
    PAGE_PROGRAM = 4


# Commands
READ_ID = 0x9E
READ = 0x03
PAGE_PROGRAM = 0x02

# Data output
FLASH_ID = [
 0x20, 0xba, 0x19, 0x10, 0x44, 0x0, 0xcc, 0xd, 0x13, 0x0, 
 0x11, 0xee, 0xff, 0x10, 0x0, 0xd4, 0xe, 0x72, 0x40, 0xee
]

class FlashMemoryModel:
    def __init__(self,
                 request: SpiMonitor,
                 response: SpiMisoDriver,
                 rst_mon: SpiSSMonitor,
                 random: Random,
                 memory: list[int] = None) -> None:
        
        # References
        self._request = request
        self._response = response
        self._random = random
        self._rst_mon = rst_mon

        self.reset()

        if (memory is not None):
            self._memory = memory
        else:
            self._memory = [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA]

        self._request.subscribe(MonitorEvent.CAPTURE, self._service)
        self._rst_mon.subscribe(MonitorEvent.CAPTURE, self._reset)

    def reset(self) -> None:
        self._index = 0
        self._address = 0
        self.state = State.IDLE

    def _reset(self,
              component: SpiSSMonitor,
              event: MonitorEvent,
              transaction: SpiResetTrans):
        self.reset()

    def write(self, address: int, data: int) -> None:
        self._memory[address] = data
        print(f'memory::{self._memory}')

    def read(self, address: int) -> int:
        print(f"Reading address: {address}")
        if address >= len(self._memory):
            print("WARNING: Reading from uninitialized memory!!!")
            return self._random.getrandbits(8)
        return self._memory[address]
    
    def flash(self, memory: list[int]) -> None:
        self._memory = memory

    def next_state(self, transaction: SpiTrans) -> None:
        if self.state == State.IDLE:
            self._index = 0
            self._address = 0
            if transaction.data == READ_ID:
                self.state = self.next_state_read_id(transaction)
            elif transaction.data == READ:
                self.state = self.next_state_read(transaction)
            elif transaction.data == PAGE_PROGRAM:
                self.state = self.next_state_page_program(transaction)
        elif self.state == State.READ_ID:
            self.state = self.next_state_read_id(transaction)
        elif self.state == State.READ:
            self.state = self.next_state_read(transaction)
        elif self.state == State.PAGE_PROGRAM:
            self.state = self.next_state_page_program(transaction)

    def next_state_read_id(self, transaction: SpiTrans) -> State:
        if (self.state == State.IDLE):
            self._index = 0
        assert self._index < len(FLASH_ID)
        self._response.enqueue(SpiTrans(data=FLASH_ID[self._index]))
        self._index += 1
        return State.READ_ID
           
    def next_state_read(self, transaction: SpiTrans) -> State:
        if (self.state == State.IDLE):
            self._index = 2
            return State.READ
        elif self._index >= 0:
            self._address += transaction.data << (8 * (self._index))
            if(self._index == 0):
                self._response.enqueue(SpiTrans(data=self.read(self._address)))
                self._address += 1
            self._index -= 1
        elif self._index == -1:
            self._response.enqueue(SpiTrans(data=self.read(self._address)))
            self._address += 1
        else:
            assert False, 'We should not be here.'
        return self.state
    
    def next_state_page_program(self, transaction: SpiTrans) -> State:
        if (self.state == State.IDLE):
            self._index = 2
            return State.PAGE_PROGRAM
        elif self._index >= 0:
            self._address += transaction.data << (8 * self._index)
            self._index -= 1
        elif self._index == -1:
            self._memory[self._address] = transaction.data
            self._address += 1
        else:
            assert False, 'We should not be here either.'
        return self.state

    def _service(self,
                 component: SpiMonitor,
                 event: MonitorEvent,
                 transaction: SpiTrans) -> None:
        assert component is self._request
        assert event is MonitorEvent.CAPTURE
        self.next_state(transaction)
