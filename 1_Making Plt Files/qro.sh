#Returns the file with number of filled and unfilled orbitals
#To be run with qro file
#Return magnetic orbital information

import pandas as pd
import numpy as np
import os

data = []
mag_orbitals = []

def degeneracy(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    
    # Reverse the lines to mimic `tac`
    lines.reverse()
    
    extracted_lines = []
    target_found = False
    count = 0
    
    for line in lines:
        if "UHF Corresponding Orbitals" in line:
            target_found = True
            continue
        if target_found:
            if "Orbital Energies of Quasi-Restricted MO's" in line or count >= 4000:
                break
            extracted_lines.append(line.strip())
            count += 1
    
    # Reverse the collected lines to restore original order and write to output file
    extracted_lines.reverse()
    extracted_lines = extracted_lines[:-6]
    for line in extracted_lines:
        # Split the line into parts
        parts = line.split()
        
        # Extract the columns
        orbital = int(parts[0].split('(')[0])  # Extract the orbital (before '(')
        degeneracy = int(parts[1][0])  # Remove parentheses from degeneracy
        energy_au = float(parts[3])# Energy in atomic units (AU)
        energy_ev = float(parts[5])  # Energy in electron volts (eV)
        
        # Append to the list
        data.append([orbital, degeneracy, energy_au, energy_ev])

    start_flag = "(*)  the overlap is weighted by the product of occupation numbers"
    end_flag = " Orbital    Overlap(*)"

    capture = False

    for i, line in enumerate(lines):
        #print(line)
        if line.strip() == start_flag:
            capture = True
            continue
        if capture and end_flag in line:
            break
        if capture:
            #print(line)
            mag_orbitals.append(line)    
    mag_orbitals.reverse()

    n = len(mag_orbitals)

    for i in range(0,n):
        mag_orbitals[i] = "".join(mag_orbitals[i])
    
    with open("mag_orbitals.txt","w") as file:
        for item in mag_orbitals:
            file.write(item+"\n")


file_path = "/home/saurabh/projects/orca_plots/v2_zn2_low/"
for file_name in os.listdir('.'):
    if file_name.endswith('.out'):
        file_path = file_name
        break


# Step 1: Extract the required lines and save to krsna.xyz
degeneracy(file_path)
# Convert the data list into a DataFrame
df = pd.DataFrame(data, columns=['Orbital', 'Degeneracy', 'Energy (AU)', 'Energy (eV)'])
df.to_csv("occupancy.xyz",sep=",", index=False)   

d1 = 0
d2 = -1
s1 = -1
s2 = -1
total = len(df)
for index,row in df.iterrows():
    if row["Degeneracy"]  == 2:
        if row["Energy (AU)"] <= -1:
            d1+=1
            d2+=1
        else:
            d2+=1
    elif row["Degeneracy"] == 1:
        s2+=1
        
if s2 != -1:
    s1 = d2+1
    s2 = d2 + s2 + 1

print(d1,d2,s1,s2,total)       



