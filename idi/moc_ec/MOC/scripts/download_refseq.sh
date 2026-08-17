#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob

#-----------------------------------
#  Check input arguments
#-----------------------------------
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 TAG /path/to/output_dir \"Species 1\" [\"Species 2\" ...]"
    exit 1
fi

TAG="$1"
OUTDIR="$2"
shift 2   # remaining args are species names

mkdir -p "$OUTDIR"
BASEDIR=$(pwd)

#-----------------------------------
#  Loop over all requested species
#-----------------------------------
for SPECIES in "$@"; do
    echo "=========================================="
    echo "Processing species: $SPECIES"
    echo "Output directory : $OUTDIR"
    echo "=========================================="

    # Clean species name → underscores for filenames
    DIRNAME=$(echo "$SPECIES" | sed 's/ /_/g')

    # Per-species temporary working directory
    WORKDIR="${BASEDIR}/${DIRNAME}_RefSeq_tmp"
    rm -rf "$WORKDIR"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    echo "Downloading RefSeq assembly for: $SPECIES"

    #-----------------------------
    #  Download from NCBI
    #-----------------------------
    datasets download genome taxon "$SPECIES" \
      --reference \
      --assembly-source refseq \
      --include genome,gff3 \
      --filename refseq_download.zip

    echo "Download complete. Unzipping..."
    unzip -o refseq_download.zip > /dev/null

    echo "Locating files..."

    #-----------------------------
    #  Find first .fna
    #-----------------------------
    FNA=$(find ncbi_dataset -type f -name "*.fna" | head -n 1 || true)

    ACCESSION="unknown"

    if [ -n "$FNA" ]; then
        # Extract accession from first FASTA header
        ACCESSION=$(grep -m 1 "^>" "$FNA" | awk '{print $1}' | sed 's/^>//')
        if [ -z "$ACCESSION" ]; then
            echo "[WARN] Could not parse accession from FASTA header, using 'unknown'"
            ACCESSION="unknown"
        else
            echo "Accession extracted from FASTA: $ACCESSION"
        fi
    else
        echo "[ERROR] No .fna file found for ${SPECIES} — cannot extract accession"
        echo "Skipping this species."
        cd "$BASEDIR"
        echo
        continue
    fi

    #-----------------------------
    #  Copy genome FASTA
    #-----------------------------
    cp "$FNA" "${OUTDIR}/${DIRNAME}_${ACCESSION}.fna"
    echo "  Saved genome FASTA as: ${OUTDIR}/${DIRNAME}_${ACCESSION}.fna"

    #-----------------------------
    #  Find and copy annotation GFF → .gff
    #-----------------------------
    GFF=$(find ncbi_dataset -type f \( -name "*.gff" -o -name "*.gff3" \) | head -n 1 || true)

    if [ -n "$GFF" ]; then
        cp "$GFF" "${OUTDIR}/${DIRNAME}_${ACCESSION}.gff"
        echo "  Saved annotation GFF as: ${OUTDIR}/${DIRNAME}_${ACCESSION}.gff"
    else
        echo "  [WARN] No .gff/.gff3 file found for ${SPECIES}, skipping annotation."
    fi

    # Back to base for next species
    cd "$BASEDIR"
    echo "Finished processing: $SPECIES"
    echo
done

#-----------------------------------
#  Combine all .fna and .gff in OUTDIR
#-----------------------------------
echo "Combining all .fna and .gff in ${OUTDIR}..."

cd "$OUTDIR"

FNA_FILES=( *.fna )
GFF_FILES=( *.gff )

if [ "${#FNA_FILES[@]}" -gt 0 ]; then
    cat "${FNA_FILES[@]}" > "${TAG}.fna"
    echo "  Created combined FASTA: ${OUTDIR}/${TAG}.fna"
else
    echo "  [WARN] No .fna files found to combine."
fi

if [ "${#GFF_FILES[@]}" -gt 0 ]; then
    cat "${GFF_FILES[@]}" > "${TAG}.gff"
    echo "  Created combined GFF: ${OUTDIR}/${TAG}.gff"
else
    echo "  [WARN] No .gff files found to combine."
fi

echo "All done. Files in $OUTDIR:"
ls -1 "$OUTDIR"
