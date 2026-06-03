#!/bin/bash

module load ORCA/5.0.3
python3 /home/nitish_ks_cy.iitr/automation/qro_automation/degenracy_distributer.py
echo "doubly-start, doubly-end, singly-start, singly-end, total"
read n1 n2 n3 n4 total
echo "n1=$n1, n2=$n2, n3=$n3, n4=$n4, total=$total"


curr=$(pwd)
mkdir -p orbital/{singly,doubly,unoccupied}
mkdir temp

echo "no of unoccupied orbitals "
read tun
if [ "$n3" -eq -1 ]; then
        n5=$((n2+1))
        n6=$((n2 + 1 + tun))
else
        n5=$((n4+1))
        n6=$((n5 + 1 + tun))
fi

cd orbital/doubly/
cp ../../*qro .
loc *qro $n1 $n2 >> $curr/temp/d_loc.out
mkdir plot
cd plot
cp ../*.loc.qro .
splotprime *.loc.qro $n1 $n2 >> $curr/temp/d_plt.out

if [ "$n3" -ne -1 ]; then

    cd ../../singly
    cp ../../*uco .
    mkdir -p plot
    cd plot
    cp ../*uco .

    # Loop from n3 to n4
    for i in $(seq $n3 $n4); do
        uplot *uco $i >> "$curr/temp/s_plt.out"
    done

fi

cd ../../unoccupied
cp ../doubly/*.loc.qro .
loc *qro $n5 $n6 >> $curr/temp/u_loc.out
mkdir plot
cd plot
cp ../*loc.loc.qro .
splotprime *.loc.qro $n5 $n6 >> $curr/temp/u_plt.out
