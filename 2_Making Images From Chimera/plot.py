# -*- coding: utf-8 -*-
# ===========================================
# AUTOMATED MO PLOTTING + CONTRIBUTION EXTRACTION
# UCSF Chimera 1.x (Python 2.7 compatible)
# ===========================================

import os
import glob
import re
from chimera import runCommand
import Midas
from Midas.midas_text import makeCommand

# Strings to attach to the text output
STR_SINGLE = "(dxy dxz dyz dx2-y2 dz2)"
STR_DOUBLE = "(dxy dxz dyz dx2-y2 dz2 - p)"

# The user should `cd` to the directory containing:
# doubly, singly, unoccupied
BASE_DIR = os.getcwd()
TARGETS = ["doubly", "singly", "unoccupied"]


def parse_mo_set(mo_list_file):
    mo_set = set()
    if not os.path.exists(mo_list_file):
        return mo_set

    with open(mo_list_file, "r") as f:
        content = f.read()

    chunks = content.replace("\n", ",").split(",")
    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue

        if "-" in chunk:
            try:
                start_s, end_s = chunk.split("-")
                start = int(start_s)
                end = int(end_s)
                mo_set.update(range(start, end + 1))
            except ValueError:
                pass
        else:
            try:
                mo_set.add(int(chunk))
            except ValueError:
                pass

    return mo_set


def derive_mos_from_plts(plt_files):
    mo_set = set()
    for plt_file in plt_files:
        name = os.path.basename(plt_file)
        mo_match = re.search(r"mo(\d+)[ab]\.plt$", name)
        if mo_match:
            mo_set.add(int(mo_match.group(1)))
    return mo_set


def get_log_files(target, target_dir):
    patterns = []
    if target == "singly":
        qro_dir = os.path.join(target_dir, "qro")
        patterns.extend([
            os.path.join(qro_dir, "*.loc.loc.log"),
            os.path.join(qro_dir, "*.log"),
            os.path.join(qro_dir, "*.loc.log"),
        ])

    patterns.extend([
        os.path.join(target_dir, "*.log"),
        os.path.join(target_dir, "*.loc.log"),
        os.path.join(target_dir, "*.loc.loc.log"),
    ])

    log_files = []
    seen = set()
    for pattern in patterns:
        for path in glob.glob(pattern):
            if path not in seen:
                seen.add(path)
                log_files.append(path)
    return log_files


def style_and_save(plt_file, out_img):
    runCommand("open " + plt_file)
    runCommand("reset fixed_view")
    makeCommand("preset apply pub 1")
    makeCommand("color byatom")
    runCommand("focus #0")
    runCommand("scale 1.3")
    runCommand("volume all style surface level 0.05 color #ffffffff0000 style surface level -0.05 color #4924f3ceffff")
    makeCommand("represent bs")
    makeCommand("volume all brightness 1.1")
    makeCommand("volume all transparency 0.44")
    runCommand("copy file " + out_img + " width 2000 height 2000 supersample 3")
    runCommand("close #1")


# Set common style for the pre-loaded .xyz molecule (Molecule #0)
runCommand("savepos fixed_view")
runCommand("preset apply pub 1")
runCommand("color byatom")
runCommand("represent stick")

for target in TARGETS:
    print "=========================================="
    print "PROCESSING FOLDER:", target
    print "=========================================="

    target_dir = os.path.join(BASE_DIR, target)
    target_plot_dir = os.path.join(target_dir, "plot")

    # Singly images come only from UCO workflow output.
    if target == "singly":
        singly_uco_plot_dir = os.path.join(target_dir, "uco", "plot")
        if os.path.exists(singly_uco_plot_dir):
            target_plot_dir = singly_uco_plot_dir
        else:
            print "Warning: singly/uco/plot not found, falling back to singly/plot"

    target_img_dir = os.path.join(target_plot_dir, "images")
    if not os.path.exists(target_img_dir):
        os.makedirs(target_img_dir)

    mo_list_file = os.path.join(target_plot_dir, "mos.txt")
    MO_SET = parse_mo_set(mo_list_file)

    if target == "singly":
        uco_candidates = []
        uco_candidates.extend(glob.glob(os.path.join(target_plot_dir, "*.uco")))
        uco_candidates.extend(glob.glob(os.path.join(target_dir, "uco", "*.uco")))
        uco_candidates.extend(glob.glob(os.path.join(target_dir, "*.uco")))

        plt_files = glob.glob(os.path.join(target_plot_dir, "*.plt"))

        if not MO_SET:
            MO_SET = derive_mos_from_plts(plt_files)

        if uco_candidates:
            print "--- Starting Image Generation for singly (UCO only) ---"
            if not plt_files:
                print "No .plt files found for singly in", target_plot_dir
            else:
                for plt_file in plt_files:
                    filename = os.path.basename(plt_file)
                    base_name = filename.replace("search.", "").replace(".plt", "")
                    out_img = os.path.join(target_img_dir, base_name + ".png")
                    style_and_save(plt_file, out_img)
                print "DONE: Images generated for singly from UCO outputs"
        else:
            print "No .uco input found for singly; skipping image generation."

    else:
        if not MO_SET:
            print "Error: " + mo_list_file + " not found or empty. Skipping " + target
            continue

        MO_LIST = sorted(list(MO_SET))
        print "Selected MOs for", target, ":", MO_LIST
        print "--- Starting Image Generation for " + target + " ---"

        for mo in MO_LIST:
            pattern = os.path.join(target_plot_dir, "*mo" + str(mo) + "a.plt")
            matches = glob.glob(pattern)
            if not matches:
                print "Skipping missing MO image file:", str(mo) + "a"
                continue

            plt_file = matches[0]
            out_img = os.path.join(target_img_dir, "mo" + str(mo) + ".png")
            style_and_save(plt_file, out_img)

        print "DONE: Images generated for", target

    # Text Extraction
    print "--- Starting Text Extraction for " + target + " ---"
    log_files = get_log_files(target, target_dir)
    output_file = os.path.join(target_img_dir, "gopal.txt")

    if target == "singly":
        print "Singly contribution source priority: singly/qro/*.loc.loc.log -> singly/qro/*.loc.log -> singly/qro/*.log -> singly/*.log"

    if not log_files:
        print "Error: No log files found for", target
        continue

    with open(output_file, "w") as fout:
        for logfile in log_files:
            fout.write("\n--- Processing: {} ---\n".format(os.path.basename(logfile)))
            with open(logfile, "r") as fin:
                seen_mos = {}

                for line in fin:
                    line = line.strip()

                    if "localized orbitals:" in line or "delocalized orbitals:" in line:
                        fout.write("\n{}\n".format(line))
                        continue

                    if not line.startswith("MO "):
                        continue

                    mo_match = re.search(r"MO\s+(\d+):", line)
                    if not mo_match:
                        continue

                    mo_number = int(mo_match.group(1))
                    if MO_SET and mo_number not in MO_SET:
                        continue

                    if target == "singly":
                        if mo_number not in seen_mos:
                            seen_mos[mo_number] = "a"
                        else:
                            seen_mos[mo_number] = "b"
                        spin_label = seen_mos[mo_number]
                    else:
                        spin_label = ""

                    pairs = re.findall(r"(\d+[A-Za-z]+)\s*-\s*(\d+\.\d+)", line)
                    if not pairs:
                        continue

                    def clean_atom(raw_atom):
                        return "".join([c for c in raw_atom if c.isalpha()])

                    if len(pairs) == 1:
                        raw_atom, val_str = pairs[0]
                        atom = clean_atom(raw_atom)
                        pct = float(val_str) * 100
                        out_str = "MO {}{} {} {} ({:.2f}%)\n".format(mo_number, spin_label, atom, STR_SINGLE, pct)
                        fout.write(out_str)
                    else:
                        atom_names = []
                        pct_details = []
                        for raw_atom, val_str in pairs:
                            atom_sym = clean_atom(raw_atom)
                            pct = float(val_str) * 100
                            atom_names.append(atom_sym)
                            pct_details.append("{} {:.2f}%".format(atom_sym, pct))

                        names_str = "-".join(atom_names)
                        details_str = " - ".join(pct_details)
                        out_str = "MO {}{} {} {} ({})\n".format(mo_number, spin_label, names_str, STR_DOUBLE, details_str)
                        fout.write(out_str)

    print "DONE: Text data written to", output_file

print "=========================================="
print "ALL TASKS COMPLETED SUCCESSFULLY"
print "=========================================="
