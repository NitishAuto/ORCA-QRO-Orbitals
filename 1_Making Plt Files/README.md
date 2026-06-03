# Step 1: PLT Generation

This folder has the scripts to localize Quasi-Restricted Orbitals (QROs) and generate the `.plt` files.

### What's inside:
* `qro.sh`: Despite the `.sh` extension, run this with Python. It parses your ORCA `.out` and `.qro` files to get the degeneracy and print out the indices for the doubly and singly occupied orbitals. 
* `qro_computing.sh`: The main bash script. It sets up the ORCA env, runs `loc`, and uses `splotprime`/`uplot` in parallel to generate the plots.
* `degenracy_distributer.py`: Actually a script for Chimera if you just want to load and inspect the generated orbitals manually. 

### How to use:
1. Put your ORCA `.out` and `.qro` files in the working directory.
2. Run `python qro.sh` to grab the start/end indices for your orbitals. It'll spit out 5 numbers (e.g. `d1 d2 s1 s2 total`).
3. Run `bash qro_computing.sh`. Paste in the numbers from the previous step when it asks for them.
4. Let it run. It'll organize everything into `doubly/`, `singly/`, and `unoccupied/` folders automatically.
