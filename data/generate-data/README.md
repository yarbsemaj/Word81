# generate-data

This directory contains scripts and data files for generating and unpacking word data for the Word81 project, which targets the ZX81 and related Z80 platforms.

## Overview

The scripts here are used to pack and unpack word lists, simulate unpacking, and provide supporting utilities for the main Word81 assembly project. The output files are used by the Z80 assembly code in the parent project.

## Directory Structure

- `packWords.js` — Packs words from `words.txt` into a compact format for use in assembly.
- `unPackSimulator.js` — Assembles `unpackWord.asm` and runs a Z80 emulator to test the unpacking script and verify the packed word data.
- `words.txt` — Source word list to be packed.
- `package.json` — Node.js package configuration for dependencies and scripts.

## Usage

### Prerequisites
- Node.js (v14 or higher recommended)

### Install dependencies

```
npm install
```


### Packing words

To pack the words from `words.txt`:

```
npm run pack
```

This will generate a packed word data file for use in the assembly project.

### Unpacking simulation

To simulate unpacking and verify the packed data:

```
npm run simulate
```

### Running tests

To run the test (which runs the simulator):

```
npm test
```

### Customization
- Edit `words.txt` to change the word list.
- Modify `packWords.js` or `unPackSimulator.js` for custom packing/unpacking logic.

## License

MIT License
