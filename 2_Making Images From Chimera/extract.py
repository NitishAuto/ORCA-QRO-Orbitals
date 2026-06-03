# -*- coding: utf-8 -*-
# =======================================================
# AUTOMATED MO NUMBER EXTRACTION
# Can be run from Command Prompt or inside Chimera
# =======================================================

import glob
import re
import os

# -------------------------------------------------------
# SETTINGS
# -------------------------------------------------------
TARGET_CONFIGS = [
    {
        "name": "doubly",
        "log_patterns": ["*.log", "*.loc.log"],
        "plot_parts": ["plot"],
    },
    {
        "name": "singly",
        # Singly contribution logs are generated from qro localization chain
        "log_patterns": ["qro/*.log", "qro/*.loc.log", "qro/*.loc.loc.log", "*.log", "*.loc.log"],
        # Singly images are generated from uco/plot
        "plot_parts": ["uco", "plot"],
    },
    {
        "name": "unoccupied",
        "log_patterns": ["*.log", "*.loc.log", "*.loc.loc.log"],
        "plot_parts": ["plot"],
    },
]
TARGET_METALS = ["Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn",
                 "Y","Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd",
                 "La","Hf","Ta","W","Re","Os","Ir","Pt","Au","Hg"]    
MIN_CONTRIB   = 2.0

# Base directory is where the script is run from (search/orbital/)
BASE_DIR = os.getcwd()


def get_input(prompt):
    try:
        # Python 2
        return raw_input(prompt)
    except NameError:
        # Python 3
        return input(prompt)


def normalize_atom_label(label):
    label = label.strip()
    m = re.match(r"^(\d+)\s*([A-Za-z]+)$", label)
    if not m:
        return None
    atom_num = m.group(1)
    atom_sym = m.group(2).capitalize()
    return atom_num + atom_sym


def parse_user_atoms(user_text):
    atoms = set()
    if not user_text:
        return atoms

    chunks = user_text.replace(",", " ").split()
    for chunk in chunks:
        norm = normalize_atom_label(chunk)
        if norm:
            atoms.add(norm)
    return atoms


user_atom_text = get_input(
    "Optional atom filters (e.g. 79H,65O,69Ni). Press Enter to skip: "
).strip()
USER_ATOMS = parse_user_atoms(user_atom_text)

if USER_ATOMS:
    print("Additional atom filters enabled: " + ", ".join(sorted(USER_ATOMS)))
else:
    print("No additional atom filters provided. Using metal-% logic only.")

for cfg in TARGET_CONFIGS:
    target = cfg["name"]
    print("\n" + "="*80)
    print("PROCESSING FOLDER: " + target)
    print("="*80)
    
    # Path to look for log files
    log_files = []
    seen_logs = set()
    for rel_pat in cfg["log_patterns"]:
        log_pattern = os.path.join(BASE_DIR, target, rel_pat)
        for path in glob.glob(log_pattern):
            if path not in seen_logs:
                seen_logs.add(path)
                log_files.append(path)
    
    # Output structure
    target_plot_dir = os.path.join(BASE_DIR, target, *cfg["plot_parts"])
    if not os.path.exists(target_plot_dir):
        os.makedirs(target_plot_dir)
        
    output_file = os.path.join(target_plot_dir, "1_screen_output.txt")
    mo_txt_file = os.path.join(target_plot_dir, "mos.txt")
    
    found_mos = set()
    
    # Open without encoding argument to ensure Python 2.7 compatibility if run in Chimera
    with open(output_file, "w") as f_out:
        if not log_files:
            msg = "ERROR: No log files found for " + target + "\n"
            print(msg)
            f_out.write(msg)
            continue
            
        for logfile in log_files:
            header = "="*80 + "\n FILE: " + os.path.basename(logfile) + "\n" + "="*80 + "\n"
            print(header.strip())
            f_out.write(header)
            
            with open(logfile, "r") as f_in:
                for line in f_in:
                    line_clean = line.strip()
                    if not line_clean.startswith("MO "):
                        continue
                        
                    mo_match = re.search(r"MO\s+(\d+):", line_clean)
                    if not mo_match: continue
                    mo_num = int(mo_match.group(1))
                    
                    pairs = re.findall(r"(\d+[A-Za-z]+)\s*-\s*(\d+\.\d+)", line_clean)
                    
                    is_valid = False

                    # Rule 1: user-requested atom labels (e.g., 79H, 65O)
                    if USER_ATOMS:
                        for atom_label, _ in pairs:
                            if normalize_atom_label(atom_label) in USER_ATOMS:
                                is_valid = True
                                break

                    # Rule 2: existing metal contribution threshold logic
                    if is_valid:
                        pass
                    else:
                        for atom_label, val_str in pairs:
                            for metal in TARGET_METALS:
                                if atom_label.endswith(metal):
                                    pct = float(val_str) * 100
                                    if pct >= MIN_CONTRIB:
                                        is_valid = True
                                    break
                            if is_valid:
                                break
                        
                    if is_valid:
                        # Print raw line
                        print(line_clean)
                        f_out.write(line_clean + "\n")
                        found_mos.add(mo_num)
                        
    # Generate copy-paste block
    if found_mos:
        sorted_mos = sorted(list(found_mos))
        
        ranges = []
        if sorted_mos:
            start = sorted_mos[0]
            end = sorted_mos[0]
            
            for n in sorted_mos[1:]:
                if n == end + 1:
                    end = n
                else:
                    if start == end:
                        ranges.append(str(start))
                    else:
                        ranges.append("{}-{}".format(start, end))
                    start = n
                    end = n
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append("{}-{}".format(start, end))
                
        final_string = ", ".join(ranges)
        
        # Save to mos.txt
        try:
            with open(mo_txt_file, "w") as f_mo:
                f_mo.write(final_string)
            save_msg = "SUCCESS: " + mo_txt_file + " has been automatically created in " + target + "!"
        except Exception as e:
            save_msg = "ERROR writing to " + mo_txt_file + ": " + str(e)
            
        footer = "\n" + "="*80 + "\n"
        footer += " " + save_msg + "\n"
        footer += "="*80 + "\n"
        footer += final_string + "\n"
        footer += "="*80 + "\n"
        
        print(footer)
        with open(output_file, "a") as f_out: # Append footer
            f_out.write(footer)
    else:
        msg = "\nNo matching orbitals found in " + target + ".\n"
        print(msg)
        with open(output_file, "a") as f_out:
            f_out.write(msg)
            
    print("\nResults for " + target + " also saved to: " + output_file)

print("\n" + "="*80)
print("ALL TASKS COMPLETED SUCCESSFULLY")
print("="*80)
