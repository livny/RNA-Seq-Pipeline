#!/usr/bin/env bash

set -u
shopt -s nullglob

# First inline barcode for each library.
# L1 and L6 are intentionally excluded.
declare -A first_inline=(
    [L2]="GTGGTTGTGGCCG"
    [L3]="GGGCTGTCTTATG"
    [L4]="GCTTATCTAGAGG"
    [L5]="GCAAGACTGCCAG"
    [L7]="GTGGTTGTGGCCG"
    [L8]="GGGCTGTCTTATG"
    [L9]="GCTTATCTAGAGG"
    [L10]="GCAAGACTGCCAG"
)

for library in L2 L3 L4 L5 L7 L8 L9 L10; do
    barcode="${first_inline[$library]}"

    for no_match in *"-${library}_"*"_no_match_R"*.fastq; do
        inline_fastq="${no_match/_no_match_/_${barcode}_}"

        if [[ ! -e "$no_match" ]]; then
            echo "Missing no_match file: $no_match"
            continue
        fi

        if [[ ! -e "$inline_fastq" ]]; then
            echo "Missing inline FASTQ: $inline_fastq"
            continue
        fi

        echo "Would replace:"
        echo "  $inline_fastq"
        echo "with symlink to:"
        echo "  $no_match"
        echo

        rm -f -- "$inline_fastq"
        ln -s -- "$(basename "$no_match")" "$inline_fastq"
    done
done
