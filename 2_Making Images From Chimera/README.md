# Step 2: Chimera Image Generation

Once you have the `.plt` files from Step 1, these scripts will filter out the noise and render nice `.png` images using UCSF Chimera.

### Scripts:
* `extract.py`: Run this from the terminal. It goes through the `.log` files from the localization step, filters the MOs based on metal contribution (or custom atoms if you prefer), and saves the list to `mos.txt`.
* `plot.py`: Run this one *inside* Chimera. It reads `mos.txt`, applies styling to the `.plt` files, saves the images to `images/`, and dumps the text info into `gopal.txt`.
* `inspect.py`: Optional Chimera script just to load and hide the `.plt` files so you can look through them manually in the Model Panel.

### Usage:
1. Run `python extract.py` in the directory that has your `doubly/`, `singly/`, and `unoccupied/` folders. It'll ask if you want to filter specific atoms.
2. Open your coordinate `.xyz` file in UCSF Chimera.
3. Open `plot.py` in Chimera (`File -> Open`, set type to Python). It handles the rest, generating your images and `gopal.txt` for the PowerPoint step.
