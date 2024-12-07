#!/bin/bash

# This script exports diagrams from draw.io files to PNG and SVG formats
# It can process either a single .drawio file or all .drawio files in the current directory
# For each diagram page in a .drawio file, it:
# 1. Exports to uncompressed XML format
# 2. Extracts the page names from the XML
# 3. Exports each page as both PNG and SVG at specified scales
#
# The script looks for draw.io at /Applications/draw.io.app/Contents/MacOS/draw.io by default
# You can override this by setting the DRAWIO_PATH environment variable, e.g.:
#   DRAWIO_PATH=/path/to/draw.io ./export-drawio.sh -i input.drawio
#
# Usage: 
#   Single file: ./export-drawio.sh -i input.drawio [--png-scale N] [--svg-scale N]
#   All files: ./export-drawio.sh --all [--png-scale N] [--svg-scale N]

# Print usage if no arguments provided
usage() {
    echo "Usage: $0 [-i input_file] [--all] [--png-scale N] [--svg-scale N]"
    echo "  -i input_file    Process single .drawio file"
    echo "  --all           Process all .drawio files in current directory"
    echo "  --png-scale N   Scale factor for PNG export (default: 10)"
    echo "  --svg-scale N   Scale factor for SVG export (default: 4)"
    exit 1
}

# Parse input arguments
input_file=""
process_all=false
png_scale=10
svg_scale=4

while [[ $# -gt 0 ]]; do
    case $1 in
        -i)
            input_file="$2"
            shift 2
            ;;
        --all)
            process_all=true
            shift
            ;;
        --png-scale)
            png_scale="$2"
            shift 2
            ;;
        --svg-scale)
            svg_scale="$2"
            shift 2
            ;;
        *)
            echo "Invalid option: $1"
            usage
            ;;
    esac
done

# Check arguments and set files array
if [ ! -z "$input_file" ]; then
    if [[ ! -f "$input_file" ]]; then
        echo "Input file $input_file not found"
        exit 1
    fi
    files=("$input_file")
elif [ "$process_all" = true ]; then
    files=(*.drawio)
else
    usage
fi

# Set draw.io path, using environment variable if provided or default path
DRAWIO_PATH=${DRAWIO_PATH:-"/Applications/draw.io.app/Contents/MacOS/draw.io"}

# Process each file
for drawio_file in "${files[@]}"; do
    # Skip if no .drawio files found
    [[ -e "$drawio_file" ]] || continue
    
    # Get filename without extension
    file="${drawio_file%.drawio}"

    # Export to XML
    "$DRAWIO_PATH" --export --format xml --uncompressed "$drawio_file"

    # Get diagram count and names
    count=$(grep -o "<diagram" "$file.xml" | wc -l)
    names=($(cat "$file.xml" | pcregrep -o1  'name="([A-z|0-9]+)"' | tr '\n' ' '))

    # Export each page as PNG and SVG
    for ((i = 0 ; i <= $count-1; i++)); do
        "$DRAWIO_PATH" --export --page-index $i -s $png_scale -t --output "$file-${names[i]}.png" "$drawio_file"
        "$DRAWIO_PATH" --export --page-index $i -s $svg_scale -t --output "$file-${names[i]}.svg" "$drawio_file"
    done
done