# -*- coding: utf-8 -*-
# ===========================================
# ORBITAL INSPECTOR
# Loads all relevant orbitals at once for manual review
# ===========================================

import os
import glob
from chimera import runCommand
import Midas
from Midas.midas_text import makeCommand

BASE_DIR = os.getcwd()
TARGETS = ["doubly", "singly", "unoccupied"]

print "=========================================="
print "         ORBITAL INSPECTOR"
print "=========================================="

# Apply general molecule styling (Assuming you've opened your XYZ manually)
runCommand("preset apply pub 1")
runCommand("color byatom")
runCommand("represent stick")
runCommand("savepos fixed_view")

loaded_count = 0

for target in TARGETS:
    target_plot_dir = os.path.join(BASE_DIR, target, "plot")
    if target == "singly":
        singly_uco_plot_dir = os.path.join(BASE_DIR, target, "uco", "plot")
        if os.path.exists(singly_uco_plot_dir):
            target_plot_dir = singly_uco_plot_dir

    if not os.path.exists(target_plot_dir):
        print "Skipping missing plot folder for:", target
        continue
        
    print "-> Gathering orbitals from:", target
    
    # 1. Singly Orbitals
    if target == "singly":
        print "   using singly UCO plot source:", target_plot_dir
        pattern = os.path.join(target_plot_dir, "*.plt")
        plt_files = glob.glob(pattern)
        for plt_file in plt_files:
            runCommand("open " + plt_file)
            loaded_count += 1
        continue
        
    # 2. Doubly and Unoccupied Orbitals
    mo_list_file = os.path.join(target_plot_dir, "mos.txt")
    MO_SET = set()
    if os.path.exists(mo_list_file):
        with open(mo_list_file, "r") as f:
            content = f.read()
        chunks = content.replace("\n", ",").split(",")
        for chunk in chunks:
            chunk = chunk.strip()
            if not chunk: continue
            if "-" in chunk:
                try:
                    start_s, end_s = chunk.split("-")
                    MO_SET.update(range(int(start_s), int(end_s) + 1))
                except ValueError: pass
            else:
                try:
                    MO_SET.add(int(chunk))
                except ValueError: pass 
                    
    MO_LIST = sorted(list(MO_SET))
    
    for mo in MO_LIST:
        # Assuming only 'a' spin plt files exist for doubly and unoccupied
        pattern = os.path.join(target_plot_dir, "*mo" + str(mo) + "a.plt")
        matches = glob.glob(pattern)
        if matches:
            runCommand("open " + matches[0])
            loaded_count += 1

if loaded_count > 0:
    # Stylize all the volumes we just loaded
    runCommand("volume all style surface level 0.05 color #ffffffff0000 style surface level -0.05 color #4924f3ceffff")
    makeCommand('represent bs')
    makeCommand('volume all brightness 1.1')
    makeCommand('volume all transparency 0.44')
    
    # Hide all volumes by default so it doesn't look like a messy blob
    import chimera
    for m in chimera.openModels.list():
        # Hide anything that isn't the primary xyz molecule coordinate file
        if not isinstance(m, chimera.Molecule):
            m.display = False
    
    print "\n=========================================="
    print "SUCCESS: Automatically loaded", loaded_count, "orbitals."
    print "=========================================="
    print "HOW TO VIEW INDIVIDUAL ORBITALS:"
    print "1. All orbitals are automatically HIDDEN for you so you start with a clean XYZ view."
    print "2. Go to 'Favorites' -> 'Model Panel' on the top toolbar."
    print "3. Check the 'S' (Show) box for the specific orbital you want to view."
    print "==========================================\n"
else:
    print "\nNo orbitals were found to load."
