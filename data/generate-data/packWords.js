import fs from 'fs'

// Alphabet mapping: A=0, B=1, ..., Z=25, apostrophe=26
const alphabet = {};
for (let i = 0; i < 26; i++) alphabet[String.fromCharCode(65 + i)] = i;

// Unpack a 4-byte array into a 5-letter word (A=0, ..., Z=25)
function unpackWord(bytes) {
    let value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    value = value >>> 7; // Right-align the 25 bits
    let chars = [];
    for (let i = 0; i < 5; i++) {
        let code = (value >> (20 - 5 * i)) & 0x1F;
        chars.push(String.fromCharCode(65 + code));
    }
    return chars.join('');
}

// Encode a 5-letter word to 25 bits, pack into 4 bytes
function packWord(word) {
    word = word.toUpperCase();
    let value = 0;
    for (let i = 0; i < 5; i++) {
        value <<= 5;
        value |= alphabet[word[i]] ?? 0;
    }
    value <<= 7; // Left-align the 25 bits in 32 bits
    return [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF
    ];

}

// Read, process, and write
const lines = fs.readFileSync('words.txt', 'utf8')
    .split(/\r?\n/);

let packedCount = 0;
let skippedCount = 0;
let errorCount = 0;
const output = [];
lines.forEach((line, i) => {
    const word = line.trim().toUpperCase();
    if (word.length === 5 && /^[A-Z]{5}$/.test(word)) {
        const packed = packWord(word);
        const unpacked = unpackWord(packed);
        if (unpacked !== word) {
            errorCount++;
            console.error(`Mismatch at line ${i + 1}: packed '${word}' -> unpacked '${unpacked}'`);
            return; 
        }
        // Create a bit string for the packed value
        const bitString = packed.map(b => b.toString(2).padStart(8, '0')).join('');
        // Only the top 25 bits are used (left-aligned)
        const usedBits = bitString.slice(0, 25);
        // Split into 5-bit chunks for comment
        const bitChunksArr = usedBits.match(/.{1,5}/g);
        const bitChunks = bitChunksArr.join(' ');
        // Decode each 5-bit chunk to a letter
        const letters = bitChunksArr.map(bits => {
            const code = parseInt(bits, 2);
            return String.fromCharCode(65 + code);
        }).join('');
        output.push(`    .BYTE ${packed.join(',')} ; ${bitChunks} ; ${letters}`);
        packedCount++;
    } else if (word.length > 0) {
        console.warn(`Skipped line ${i + 1}: '${line}' (not a valid 5-letter A-Z word)`);
        skippedCount++;
    }
});

fs.writeFileSync('../words_packed.asm', output.join('\n'));
console.log(`Packing complete! Packed: ${packedCount}, Skipped: ${skippedCount}, Errors: ${errorCount}`);