#!/bin/bash

# Start the master timer
TOTAL_START=$SECONDS

# ==========================================
# --- ENVIRONMENT SETUP ---
# ==========================================
source /home/apps/spack/share/spack/setup-env.sh

module load ORCA/5.0.3
module load openmpi/4.1.3
module load spack
module load anaconda3/2021.05-gcc-11.2.0-zhjd


export RSH_COMMAND="/usr/bin/ssh -x"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/apps/spack/opt/spack/linux-centos7-cascadelake/gcc-11.2.0/openmpi-4.1.1-updjfz7lmfy7zbiaxq2xdhnpprxpzk54/lib
export param="--mca opal_common_ucx_opal_mem_hooks 1"
export ORCADIR=/home/apps/ORCA503/bin
export PATH=$ORCADIR:$PATH 

# Safely limit simultaneous plotting jobs to prevent RAM overflow
BATCH_SIZE=32

# ==========================================
# --- INPUTS & DIRECTORY SETUP ---
# ==========================================
if command -v python3 &>/dev/null; then
    python3 /home/$USER/automation/qro_automation/degenracy_distributer.py
else
    echo "Python3 not found. Please enter values manually below:"
fi

echo "doubly-start, doubly-end, singly-start, singly-end, total"
read n1 n2 n3 n4 total
echo "n1=$n1, n2=$n2, n3=$n3, n4=$n4, total=$total"

curr=$(pwd)
mkdir -p "$curr/orbital/singly" "$curr/orbital/doubly" "$curr/orbital/unoccupied"
mkdir -p "$curr/temp"

echo "no of unoccupied orbitals "
read tun

if [ "$n3" -eq -1 ]; then
        n5=$((n2+1))
        n6=$((n2 + 1 + tun))
else
        n5=$((n4+1))
        n6=$((n5 + 1 + tun))
fi

# ==========================================
# --- DOUBLY OCCUPIED ---
# ==========================================
cd "$curr/orbital/doubly/" || exit
cp "$curr/"*.qro . 2>/dev/null

echo "Localizing Doubly Occupied Orbitals..."
LOC_D_START=$SECONDS
loc *.qro $n1 $n2 >> "$curr/temp/d_loc.out"
LOC_D_TIME=$((SECONDS - LOC_D_START))

mkdir -p plot && cd plot
cp ../*.loc.qro . 2>/dev/null

echo "Plotting Doubly Occupied Orbitals (Rolling Queue of $BATCH_SIZE)..."
PLT_D_START=$SECONDS
for i in $(seq $n1 $n2); do
    (
        mkdir -p "tmp_$i" && cd "tmp_$i" || exit
        ln ../*.loc.qro . 2>/dev/null || cp ../*.loc.qro . 2>/dev/null
        splotprime *.loc.qro $i $i >> "$curr/temp/d_plt_${i}.out" 2>&1
        find . -maxdepth 1 -type f ! -name "*.loc.qro" -exec mv {} ../ \;
        cd .. && rm -rf "tmp_$i"
    ) &
    
    while [ $(jobs -p | wc -l) -ge $BATCH_SIZE ]; do
        sleep 0.5
    done
done
wait 
PLT_D_TIME=$((SECONDS - PLT_D_START))


# ==========================================
# --- SINGLY OCCUPIED ---
# ==========================================
PLT_S_TIME=0 # Default to 0 in case it skips
if [ "$n3" -ne -1 ]; then
    cd "$curr/orbital/singly" || exit
    cp "$curr/"*.uco . 2>/dev/null
    mkdir -p plot && cd plot
    cp ../*.uco . 2>/dev/null

    echo "Plotting Singly Occupied Orbitals (Rolling Queue of $BATCH_SIZE)..."
    PLT_S_START=$SECONDS
    for i in $(seq $n3 $n4); do
        (
            mkdir -p "tmp_$i" && cd "tmp_$i" || exit
            ln ../*.uco . 2>/dev/null || cp ../*.uco . 2>/dev/null
            uplot *.uco $i >> "$curr/temp/s_plt_${i}.out" 2>&1
            find . -maxdepth 1 -type f ! -name "*.uco" -exec mv {} ../ \;
            cd .. && rm -rf "tmp_$i"
        ) &
        
        while [ $(jobs -p | wc -l) -ge $BATCH_SIZE ]; do
            sleep 0.5
        done
    done
    wait
    PLT_S_TIME=$((SECONDS - PLT_S_START))
fi


# ==========================================
# --- UNOCCUPIED ---
# ==========================================
cd "$curr/orbital/unoccupied" || exit
cp "$curr/orbital/doubly/"*.loc.qro . 2>/dev/null

echo "Localizing Unoccupied Orbitals..."
LOC_U_START=$SECONDS
loc *.loc.qro $n5 $n6 >> "$curr/temp/u_loc.out"
LOC_U_TIME=$((SECONDS - LOC_U_START))

mkdir -p plot && cd plot
cp ../*.loc.loc.qro . 2>/dev/null

echo "Plotting Unoccupied Orbitals (Rolling Queue of $BATCH_SIZE)..."
PLT_U_START=$SECONDS
for i in $(seq $n5 $n6); do
    (
        mkdir -p "tmp_$i" && cd "tmp_$i" || exit
        ln ../*.loc.loc.qro . 2>/dev/null || cp ../*.loc.loc.qro . 2>/dev/null
        splotprime *.loc.loc.qro $i $i >> "$curr/temp/u_plt_${i}.out" 2>&1
        find . -maxdepth 1 -type f ! -name "*.loc.loc.qro" -exec mv {} ../ \;
        cd .. && rm -rf "tmp_$i"
    ) &
    
    while [ $(jobs -p | wc -l) -ge $BATCH_SIZE ]; do
        sleep 0.5
    done
done
wait
PLT_U_TIME=$((SECONDS - PLT_U_START))

# ==========================================
# --- TIMING & COMPLETION ---
# ==========================================
TOTAL_TIME=$((SECONDS - TOTAL_START))

echo ""
echo "================================================="
echo "       QRO POST-PROCESSING TIMING SUMMARY        "
echo "================================================="
printf "Localize Doubly Orbitals : %d mins %d secs\n" $((LOC_D_TIME / 60)) $((LOC_D_TIME % 60))
printf "Plot Doubly Orbitals     : %d mins %d secs\n" $((PLT_D_TIME / 60)) $((PLT_D_TIME % 60))

if [ "$n3" -ne -1 ]; then
    printf "Plot Singly Orbitals     : %d mins %d secs\n" $((PLT_S_TIME / 60)) $((PLT_S_TIME % 60))
else
    printf "Plot Singly Orbitals     : Skipped (N/A)\n"
fi

printf "Localize Unocc Orbitals  : %d mins %d secs\n" $((LOC_U_TIME / 60)) $((LOC_U_TIME % 60))
printf "Plot Unocc Orbitals      : %d mins %d secs\n" $((PLT_U_TIME / 60)) $((PLT_U_TIME % 60))
echo "-------------------------------------------------"
printf "TOTAL EXECUTION TIME     : %d mins %d secs\n" $((TOTAL_TIME / 60)) $((TOTAL_TIME % 60))
echo "================================================="
