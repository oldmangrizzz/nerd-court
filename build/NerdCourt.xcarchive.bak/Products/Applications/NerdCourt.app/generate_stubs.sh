#!/bin/bash
# Generate minimal WAV stubs for Nerd Court sound effects.
# Each stub is 0.15s of near-silence at 22050Hz mono 16-bit PCM.
# These are PLACEHOLDERS — replace with real sound design assets.

SAMPLE_RATE=22050
DURATION=0.15
NUM_SAMPLES=$(echo "$SAMPLE_RATE * $DURATION" | bc | cut -d. -f1)
DATA_SIZE=$((NUM_SAMPLES * 2))  # 16-bit = 2 bytes per sample
FILE_SIZE=$((DATA_SIZE + 36))   # 44-byte header - 8 bytes for RIFF/size

generate_wav() {
    local name="$1"
    local out="${name}.wav"
    # RIFF header
    printf "RIFF" > "$out"
    # File size (little-endian 32-bit)
    printf '%08x' $FILE_SIZE | xxd -r -p | dd of="$out" bs=1 seek=4 conv=notrunc 2>/dev/null
    printf "WAVE" | dd of="$out" bs=1 seek=8 conv=notrunc 2>/dev/null
    # fmt chunk
    printf "fmt " | dd of="$out" bs=1 seek=12 conv=notrunc 2>/dev/null
    printf '%08x' 16 | xxd -r -p | dd of="$out" bs=1 seek=16 conv=notrunc 2>/dev/null  # chunk size
    printf '%04x' 1 | xxd -r -p | dd of="$out" bs=1 seek=20 conv=notrunc 2>/dev/null   # PCM
    printf '%04x' 1 | xxd -r -p | dd of="$out" bs=1 seek=22 conv=notrunc 2>/dev/null   # mono
    printf '%08x' $SAMPLE_RATE | xxd -r -p | dd of="$out" bs=1 seek=24 conv=notrunc 2>/dev/null
    printf '%08x' $((SAMPLE_RATE * 2)) | xxd -r -p | dd of="$out" bs=1 seek=28 conv=notrunc 2>/dev/null  # byte rate
    printf '%04x' 2 | xxd -r -p | dd of="$out" bs=1 seek=32 conv=notrunc 2>/dev/null   # block align
    printf '%04x' 16 | xxd -r -p | dd of="$out" bs=1 seek=34 conv=notrunc 2>/dev/null  # bits per sample
    # data chunk
    printf "data" | dd of="$out" bs=1 seek=36 conv=notrunc 2>/dev/null
    printf '%08x' $DATA_SIZE | xxd -r -p | dd of="$out" bs=1 seek=40 conv=notrunc 2>/dev/null
    # near-silence samples
    dd if=/dev/zero bs=$DATA_SIZE count=1 >> "$out" 2>/dev/null
    echo "  ✓ $out"
}

cd "$(dirname "$0")"
echo "Generating Nerd Court sound stubs..."
for sting in objection_sting gavel_strike finisher_impact dramatic_reveal \
             deadpool_entrance phase_transition verdict_drumroll crowd_gasp crowd_laugh; do
    generate_wav "$sting"
done
echo "Done."
