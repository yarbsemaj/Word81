import {compile} from '@andrivet/z80-assembler';
import { Z80 } from 'z80-emulator';
import { Hal } from './z80hal.js';
import fs from 'fs';

// Your Z80 routine as a string (must include a RET at the end)
const z80src = `
_A    .equ $26
    ORG 0x8000
    LD A, (0x900A) ; Load odd/even flag
    OR A
    JR NZ, ODD
    LD HL,0x9000
UNPACK_WORD_START:
    LD DE,0x9100
    CALL UNPACK_WORD
    HALT

ODD:
    LD HL,0x9001
    JR UNPACK_WORD_START
include "../../libs/unpackWord.asm"
`;

console.log('Assembling Z80 unpack routine...');
// Assemble the code
const compileOuput = compile('file',z80src, (msg) => {
  return fs.readFileSync(`${msg}`, 'utf8');
});

console.log('Loading Z80 unpack routine into simulator...');
// Get the machine code bytes
const bytes = Uint8Array.from(compileOuput.bytes);

// Read packed bytes from words_packed.asm
const packedLines = fs.readFileSync('../words_packed.asm', 'utf8')
  .split('\n')
  .filter(line => line.trim().startsWith('.BYTE'));

  const outputAddr = 0x9100;

let errors = 0;
for (let idx = 0; idx < packedLines.length; idx++) {
  const packed = packedLines[idx].match(/\.BYTE\s+([^;]+)/)[1].split(',').map(b => parseInt(b.trim()));
  const odd = packedLines[idx].includes('(odd)');
  // Extract expected word from comment
  const commentMatch = packedLines[idx].match(/;\s*([A-Z]{5})\s*$/);
  const expected = commentMatch ? commentMatch[1] : '';
  // Set up HAL and memory for each word
  const hal = new Hal();
  hal.memory.set(bytes, 0x8000); // Load code at 0x8000
  hal.memory.set(packed, odd ? 0x9001 : 0x9000); // Place packed word at 0x9000
  hal.memory[0x900A] = odd ? 1 : 0; // Set odd/even flag
  // Create Z80 instance, passing HAL
  const cpu = new Z80(hal);
  cpu.regs.pc = 0x8000; // Set PC to start of our code
  // Run until HALT (0x76) or RET (0xC9)
  let steps = 0;
  while (steps < 10000) {
    const opcode = hal.memory[cpu.regs.pc];
    if (opcode === 0x76 || opcode === 0xC9) break;
    cpu.step();
    steps++;
  }
  // Read output
  const output = [];
  for (let i = 0; i < 5; i++) {
    output.push(String.fromCharCode(hal.memory[outputAddr + i] - 38 + 65)); // Convert back to A-Z
  }
  const decoded = output.join('');
  const ok = decoded === expected;
  if (!ok) {
    errors++;
    console.error(`Mismatch [${idx}]: decoded='${decoded}' expected='${expected}' packed=${packed}`);
  }
}
if (errors === 0) {
  console.log('All words decoded correctly!');
} else {
  console.log(`${errors} mismatches found.`);
}
