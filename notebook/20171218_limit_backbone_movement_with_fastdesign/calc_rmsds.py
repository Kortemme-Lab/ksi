#!/usr/bin/env python3

import pandas as pd
from prody import *
from pylab import *
from pathlib import Path
from shutil import get_terminal_size
from pprint import pprint

pd.set_option('display.width', get_terminal_size().columns)

class Output:
    def __init__(self, path):
        self.path = path
        self.title = Path(path).stem.replace('_', ' ').title()
        self.atoms = parsePDB(path)
        self.bb = self.atoms.select('bb').copy()
        self.ca = self.atoms.select('ca').copy()
        self.loop = self.atoms.select('bb resnum 26:51').copy()


reference = ref = \
        Output('e38_lig_dimer.pdb')
designs = [ #
        Output('outputs/vanilla_e38_lig_dimer.pdb'),
        Output('outputs/restrain_no_e38_lig_dimer.pdb'),
        Output('outputs/restrain_none_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_ramp_no_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_ramp_yes_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_cli_fixed_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_cli_loop_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_xml_fixed_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_foldtree_e38_lig_dimer.pdb'),
        Output('outputs/restrain_no_movemap_xml_loop_foldtree_e38_lig_dimer.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_cart_e38_lig_dimer.pdb'),
        Output('outputs/restrain_no_movemap_xml_loop_cart_e38_lig_dimer.pdb'),
]

# Calculate RMSDs without superimposition.

def calc_rmsd_for_subset(a, b, sele):
    return calcRMSD(a.atoms.select(sele), b.atoms.select(sele))

def calc_rmsd_for_subset_manually(a, b, sele):
    # I wanted to manually do the RMSD calculation to confirm that prody is 
    # doing what I think it should (it is), and to add some debugging output.
    msd = 0
    a = a.atoms.select(sele).copy()
    b = b.atoms.select(sele).copy()
    n = len(a)

    for i in range(n):
        name = a[i].getName()
        resi = a[i].getResnum()
        atom_a = a[i].getCoords()
        atom_b = b[i].getCoords()
        dist = np.linalg.norm(atom_b - atom_a)**2
        msd += dist / n
        print(f'  {resi:3d}  {name:2s}  a={atom_a}  b={atom_b}  d={dist:.6f}  msd={msd:.6f}')

    return np.sqrt(msd)


# Define different sets of residues to compare.

bb = 'bb'  # Could also try using 'ca'
loop_a, loop_b = '26to51', '198to203'
loops = f'resnum {loop_a} {loop_b}'
selections = [ #
    ('Everything',    f'{bb}'),
    ('Chain A Loop',  f'{bb} resnum {loop_a}'),
    ('Chain B Loop',  f'{bb} resnum {loop_b}'),
    ('Both Loops',    f'{bb} {loops}'),
    ('Scaffold-only', f'{bb} not {loops}'),
]

for design in designs:
    print(design.title)

    rows = {
        name: {
            'name': name,
            'selection': sele,
            'num_atoms': len(ref.atoms.select(sele)),
        }
        for name, sele in selections
    }

    for name, sele in selections:
        rows[name]['unaligned'] = calc_rmsd_for_subset(ref, design, sele)

    superpose(design.bb, reference.bb)

    for name, sele in selections:
        rows[name]['aligned'] = calc_rmsd_for_subset(ref, design, sele)

    rows = list(rows.values())
    df = pd.DataFrame(
            rows,
            columns=list(rows[0].keys()),
    )
    print(df)
    print()



