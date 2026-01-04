// z80hal.js - Hardware Abstraction Layer for Z80 emulation
// Implements the HAL interface for a Z80 emulator
import { Z80 } from 'z80-emulator';

/**
 * Hardware abstraction layer. Implements the HAL interface for the Z80 emulator.
 */
export class Hal {
    constructor() {
        this.memory = new Uint8Array(0x10000);
        this.tStateCount = 0;
    }

    /**
     * Read a byte of memory.
     */
    readMemory(address) {
        return this.memory[address & 0xFFFF];
    }

    /**
     * Write a byte to memory.
     */
    writeMemory(address, value) {
        this.memory[address & 0xFFFF] = value & 0xFF;
    }

    /**
     * Contend memory at an address (stub for compatibility).
     */
    contendMemory(address) {
        // No contention emulation
    }

    /**
     * Read a byte from a port.
     */
    readPort(address) {
        // No port emulation, return 0xFF
        return 0xFF;
    }

    /**
     * Write a byte to a port.
     */
    writePort(address, value) {
        // No port emulation
    }

    /**
     * Contend a port address (stub for compatibility).
     */
    contendPort(address) {
        // No contention emulation
    }
}
