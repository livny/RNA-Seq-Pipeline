#!/usr/bin/env python3
"""
KeyMetrics analysis plotting script.

Usage:
  use Python-3.9
  python keymetrics_analysis2.py /path/to/KeyMetrics.txt [--outdir /path/to/output]

Output:
  Writes KeyMetrics_analysis.pdf in the same directory as the input file
"""

import os
import re
import argparse

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


def extract_num(pattern, val, default=999999):
    m = re.search(pattern, str(val))
    if m:
        try:
            return int(m.group(1))
        except Exception:
            return default
    return default


def make_keymetrics_plots(keymetrics_path, outdir=None):
    df = pd.read_csv(keymetrics_path, sep="\t")

    # Column names
    col_total = "Total_reads"
    col_rna = "RNA_concentration"
    col_pool = "Pool_ID"
    col_plate = "Plate/Box_ID"
    col_inline = "Inline_Name"
    col_rrna = "rRNA_pcnt_of_counted"
    col_sample = "Sample_loc"
    col_time = "Timepoint"
    col_treat = "Treatment"
    col_final = "Final_Sample_Loc"
    col_aligned = "pcnt_aligned"
    col_cds = "CDS_total_counts_for_replicon"

    # Numeric conversions
    df[col_total] = pd.to_numeric(df[col_total], errors="coerce")
    df[col_rna] = pd.to_numeric(df[col_rna], errors="coerce")
    df[col_rrna] = pd.to_numeric(df[col_rrna], errors="coerce")
    df[col_aligned] = pd.to_numeric(df[col_aligned], errors="coerce")
    df[col_cds] = pd.to_numeric(df[col_cds], errors="coerce")

    df = df.dropna(subset=[col_total]).copy()

    # Sorted categorical axes
    pools = sorted(df[col_pool].dropna().unique(),
                   key=lambda x: extract_num(r"p(\d+)", x))
    plates = sorted(df[col_plate].dropna().unique())
    inlines = sorted(df[col_inline].dropna().unique(),
                     key=lambda x: extract_num(r"L(\d+)", x))
    samples = sorted(df[col_sample].dropna().unique())

    df["pool_x"] = df[col_pool].map({p: i for i, p in enumerate(pools)})
    df["plate_x"] = df[col_plate].map({p: i for i, p in enumerate(plates)})
    df["inline_x"] = df[col_inline].map({p: i for i, p in enumerate(inlines)})
    df["sample_x"] = df[col_sample].map({p: i for i, p in enumerate(samples)})

    # Timepoint colors (72h = purple)
    time_color = {
        "6h": "blue",
        "16h": "green",
        "72h": "purple",
        "120h": "red",
    }
    df["color_time"] = df[col_time].astype(str).map(
        lambda t: time_color.get(t, "gray")
    )

    # Treatment colors
    treatments = sorted(df[col_treat].astype(str).unique())
    treat_to_idx = {t: i for i, t in enumerate(treatments)}

    # Output PDF
    outdir = outdir or os.path.dirname(os.path.abspath(keymetrics_path))
    os.makedirs(outdir, exist_ok=True)
    out_pdf = os.path.join(outdir, "KeyMetrics_analysis.pdf")

    with PdfPages(out_pdf) as pdf:

        def save():
            plt.tight_layout(pad=3)
            pdf.savefig(bbox_inches="tight")
            plt.close()

        # 1. Total Reads vs RNA concentration
        plt.figure(figsize=(10, 6))
        plt.scatter(df[col_rna], df[col_total], s=10, color="blue")
        plt.yscale("log")
        plt.xlabel("RNA Concentration (ng/µL)")
        plt.ylabel("Total Reads (log10)")
        plt.title("Total Reads vs RNA Concentration")
        plt.grid(True)
        save()

        # 2. Total Reads vs Pool ID
        plt.figure(figsize=(16, 6))
        plt.scatter(df["pool_x"], df[col_total], s=10, color="blue")
        plt.yscale("log")
        plt.xlabel("Pool ID")
        plt.ylabel("Total Reads (log10)")
        plt.title("Total Reads vs Pool ID")
        plt.xticks(range(len(pools)), pools, rotation=90)
        plt.grid(True)
        save()

        # 3. rRNA % vs Pool ID
        df_rrna = df.dropna(subset=[col_rrna])
        plt.figure(figsize=(16, 6))
        plt.scatter(df_rrna["pool_x"], df_rrna[col_rrna], s=10, color="blue")
        plt.xlabel("Pool ID")
        plt.ylabel("rRNA % of counted reads")
        plt.title("rRNA % Reads vs Pool ID")
        plt.xticks(range(len(pools)), pools, rotation=90)
        plt.grid(True)
        save()

        # 4. % aligned vs Pool ID
        df_aln = df.dropna(subset=[col_aligned])
        plt.figure(figsize=(16, 6))
        plt.scatter(df_aln["pool_x"], df_aln[col_aligned], s=10, color="blue")
        plt.xlabel("Pool ID")
        plt.ylabel("% aligned")
        plt.title("% aligned vs Pool ID")
        plt.xticks(range(len(pools)), pools, rotation=90)
        plt.grid(True)
        save()

        
        # 4b. % aligned vs Inline barcode (dot plot)
        if col_inline in df.columns:
            df_aln_inl = df.dropna(subset=[col_aligned, col_inline]).copy()
            if len(df_aln_inl) > 0:
                inlines = sorted(
                    df_aln_inl[col_inline].dropna().unique().tolist(),
                    key=lambda x: extract_num(r"(\d+)", x),
                )
                inline_to_idx = {name: i for i, name in enumerate(inlines)}
                df_aln_inl["inline_x"] = df_aln_inl[col_inline].map(inline_to_idx)

                plt.figure(figsize=(16, 6))
                plt.scatter(df_aln_inl["inline_x"], df_aln_inl[col_aligned], s=10)
                plt.xlabel("Inline barcode ID")
                plt.ylabel("% aligned")
                plt.title("% aligned vs Inline barcode")
                plt.xticks(range(len(inlines)), inlines, rotation=90)
                plt.grid(True)
                save()

        # 4c. Total reads vs Inline barcode (dot plot; log10 transform)
        if col_inline in df.columns:
            df_tr_inl = df.dropna(subset=[col_total, col_inline]).copy()
            if len(df_tr_inl) > 0:
                inlines = sorted(
                    df_tr_inl[col_inline].dropna().unique().tolist(),
                    key=lambda x: extract_num(r"(\d+)", x),
                )
                inline_to_idx = {name: i for i, name in enumerate(inlines)}
                df_tr_inl["inline_x"] = df_tr_inl[col_inline].map(inline_to_idx)

                df_tr_inl["total_reads_log10"] = np.log10(df_tr_inl[col_total].astype(float) + 1.0)

                plt.figure(figsize=(16, 6))
                plt.scatter(df_tr_inl["inline_x"], df_tr_inl["total_reads_log10"], s=10)
                plt.xlabel("Inline barcode ID")
                plt.ylabel("log10(Total reads + 1)")
                plt.title("Total reads vs Inline barcode (log10)")
                plt.xticks(range(len(inlines)), inlines, rotation=90)
                plt.grid(True)
                save()
# 5. CDS counts vs Pool ID (log10)
        df_cds = df.dropna(subset=[col_cds])
        plt.figure(figsize=(16, 6))
        plt.scatter(df_cds["pool_x"], df_cds[col_cds], s=10, color="blue")
        plt.yscale("log")
        plt.xlabel("Pool ID")
        plt.ylabel("CDS total counts (log10)")
        plt.title("CDS_total_counts_for_replicon vs Pool ID")
        plt.xticks(range(len(pools)), pools, rotation=90)
        plt.grid(True)
        save()

        # 6. Rearray plate location
        df_fp = df.dropna(subset=[col_final]).copy()
        df_fp["final_plate"] = df_fp[col_final].astype(str).str[:-3]
        final_plates = sorted(df_fp["final_plate"].unique())
        df_fp["fp_x"] = df_fp["final_plate"].map(
            {p: i for i, p in enumerate(final_plates)}
        )

        plt.figure(figsize=(14, 6))
        plt.scatter(df_fp["fp_x"], df_fp[col_total], s=10, color="blue")
        plt.yscale("log")
        plt.xlabel("Rearray_plate_location")
        plt.ylabel("Total Reads (log10)")
        plt.title("Total Reads vs Rearray_plate_location")
        plt.xticks(range(len(final_plates)), final_plates, rotation=90)
        plt.grid(True)
        save()

        # 7. Rearray well plot (colored by plate)
        df_w = df_fp.copy()
        df_w["well"] = df_w[col_final].astype(str).str[-3:]

        wells = sorted(
            df_w["well"].unique(),
            key=lambda x: (x[0], int(x[1:])) if len(x) == 3 else (x, 999),
        )
        df_w["well_x"] = df_w["well"].map({w: i for i, w in enumerate(wells)})

        plate_list = sorted(df_w["final_plate"].unique())
        plate_to_idx = {p: i for i, p in enumerate(plate_list)}
        colors = [plt.cm.tab20(plate_to_idx[p] % 20) for p in df_w["final_plate"]]

        plt.figure(figsize=(16, 6))
        plt.scatter(df_w["well_x"], df_w[col_total], color=colors, s=14)
        plt.yscale("log")
        plt.xlabel("Rearray well (last 3 chars)")
        plt.ylabel("Total Reads (log10)")
        plt.title("Total Reads vs Final_Sample_Loc (Well Only, Colored by Plate)")
        plt.xticks(range(len(wells)), wells, rotation=90)
        plt.grid(True)

        for p, idx in plate_to_idx.items():
            plt.scatter([], [], color=plt.cm.tab20(idx % 20), label=p, s=30)
        plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left", title="Plate")
        save()

        # 8. Sample_loc colored by timepoint
        plt.figure(figsize=(16, 6))
        plt.scatter(df["sample_x"], df[col_total], c=df["color_time"], s=12)
        plt.yscale("log")
        plt.xlabel("Sample_loc")
        plt.ylabel("Total Reads (log10)")
        plt.title("Total Reads vs Sample_loc (Colored by Timepoint)")
        plt.xticks(range(len(samples)), samples, rotation=90)
        plt.grid(True)

        for tp, col in time_color.items():
            plt.scatter([], [], color=col, label=tp, s=30)
        plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left", title="Timepoint")
        save()

    return out_pdf


def main():
    parser = argparse.ArgumentParser(
        description="Generate KeyMetrics_analysis.pdf from a KeyMetrics TSV file."
    )
    parser.add_argument("keymetrics_path", help="Path to KeyMetrics.txt")
    parser.add_argument("--outdir", default=None, help="Output directory for KeyMetrics_analysis.pdf (default: input file directory)")
    args = parser.parse_args()

    out_pdf = make_keymetrics_plots(args.keymetrics_path, outdir=args.outdir)
    print("Saved PDF to:", out_pdf)


if __name__ == "__main__":
    main()
