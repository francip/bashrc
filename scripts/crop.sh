#!/bin/bash

# Check if correct number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <crop_spec> <input_file>"
    echo "Crop spec examples: h1v (left half vertical), h2h (top half horizontal), q1 (top-left quarter), q3v (bottom-left quarter)"
    exit 1
fi

CROP_SPEC="$1"
INPUT_FILE="$2"
OUTPUT_FILE="${INPUT_FILE%.*}-${CROP_SPEC}.${INPUT_FILE##*.}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file does not exist"
    exit 1
fi

# Validate crop spec format (e.g., h1v, q2, q3v)
if ! [[ "$CROP_SPEC" =~ ^(h[1-2][vh]|q[1-4][vh]?)$ ]]; then
    echo "Error: Invalid crop spec. Use h[1-2][v|h] for halves or q[1-4][v|h]? for quarters"
    exit 1
fi

# Extract crop type (h or q), part number, and split type (v, h, or empty)
CROP_TYPE="${CROP_SPEC:0:1}"      # h or q
PART_NUM="${CROP_SPEC:1:1}"       # 1, 2, 3, or 4
SPLIT_TYPE="${CROP_SPEC:2:1}"     # v, h, or empty

# Get image dimensions using ImageMagick
DIMENSIONS=$(magick identify -format "%w %h" "$INPUT_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Failed to read image dimensions"
    exit 1
fi
read WIDTH HEIGHT <<< "$DIMENSIONS"

# Check if dimensions are divisible by 2
if [ $((WIDTH % 2)) -ne 0 ] || [ $((HEIGHT % 2)) -ne 0 ]; then
    echo "Error: Image dimensions ($WIDTH x $HEIGHT) must be divisible by 2"
    exit 1
fi

# Calculate crop parameters
if [ "$CROP_TYPE" = "h" ]; then
    # Half crop
    if [ "$PART_NUM" != "1" ] && [ "$PART_NUM" != "2" ]; then
        echo "Error: Half crop part number must be 1 or 2"
        exit 1
    fi
    if [ "$SPLIT_TYPE" != "v" ] && [ "$SPLIT_TYPE" != "h" ]; then
        echo "Error: Half crop requires v or h suffix"
        exit 1
    fi
    if [ "$SPLIT_TYPE" = "v" ]; then
        # Vertical split (left/right halves)
        CROP_WIDTH=$((WIDTH / 2))
        CROP_HEIGHT=$HEIGHT
        if [ "$PART_NUM" = "1" ]; then
            CROP="${CROP_WIDTH}x${CROP_HEIGHT}+0+0"  # Left half
        else
            CROP="${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_WIDTH}+0"  # Right half
        fi
    else
        # Horizontal split (top/bottom halves)
        CROP_WIDTH=$WIDTH
        CROP_HEIGHT=$((HEIGHT / 2))
        if [ "$PART_NUM" = "1" ]; then
            CROP="${CROP_WIDTH}x${CROP_HEIGHT}+0+0"  # Top half
        else
            CROP="${CROP_WIDTH}x${CROP_HEIGHT}+0+${CROP_HEIGHT}"  # Bottom half
        fi
    fi
else
    # Quarter crop
    CROP_WIDTH=$((WIDTH / 2))
    CROP_HEIGHT=$((HEIGHT / 2))
    case "$PART_NUM" in
        1) CROP="${CROP_WIDTH}x${CROP_HEIGHT}+0+0" ;;               # Top-left
        2) CROP="${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_WIDTH}+0" ;;   # Top-right
        3) CROP="${CROP_WIDTH}x${CROP_HEIGHT}+0+${CROP_HEIGHT}" ;;  # Bottom-left
        4) CROP="${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_WIDTH}+${CROP_HEIGHT}" ;; # Bottom-right
    esac
fi

# Perform the crop
magick "$INPUT_FILE" -crop "$CROP" "$OUTPUT_FILE"

# Check if conversion was successful
if [ $? -eq 0 ]; then
    echo "Created $OUTPUT_FILE"
else
    echo "Error: Failed to crop image"
    exit 1
fi