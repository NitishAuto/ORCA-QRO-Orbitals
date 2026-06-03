# QRO Orbital Localisation & Plotting Workflow

Hey, this is a set of scripts I use to automate localising and plotting Molecular Orbitals (MOs) from ORCA outputs. Instead of doing everything manually, these scripts handle the bulk of the work across three main steps:

1. **1_Making Plt Files**: Takes the raw ORCA `.out` and `.qro` files, figures out the orbital ranges, runs localization, and batches out the `.plt` files.
2. **2_Making Images From Chimera**: Python scripts for UCSF Chimera. It filters the orbitals based on metal contribution, renders the actual `.png` images, and grabs the orbital text data.
3. **3_Plotting in PPT Macro**: A quick VBA macro to dump all those images and data into a clean PowerPoint grid.

Check inside each folder for specific instructions on how to run them.
