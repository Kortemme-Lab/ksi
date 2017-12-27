#!/usr/bin/env python3

"""\
Calculate and report metrics for the FastDesign runs.

Usage:
    calc_rmsds.py [<keywords>...]

Arguments:
    <keywords>
        Only report metrics for simulations with all of the given keywords in 
        their names.
"""

import re, docopt
import pandas as pd
from prody import *
from pylab import *
from pathlib import Path
from shutil import get_terminal_size
from pprint import pprint

pd.set_option('display.width', get_terminal_size().columns)

class Output:
    def __init__(self, path):
        self.path = Path(path)
        self.slug = self.path.name.split('.')[0]
        self.title = self.slug.replace('_', ' ').upper()

        # Don't try to parse the file if it doesn't exist.  This makes it 
        # easier for me to analyze data before all the runs have finished.
        if self.path.exists():
            self.atoms = parsePDB(path)
            self.bb = self.atoms.select('bb')


reference = ref = \
        Output('alfa.pdb.gz')
designs = [ #
        Output('outputs/vanilla.alfa.pdb'),
        Output('outputs/restrain_no.alfa.pdb'),
        Output('outputs/restrain_none.alfa.pdb'),
        Output('outputs/restrain_yes.alfa.pdb'),
        Output('outputs/restrain_yes_ramp_no.alfa.pdb'),
        Output('outputs/restrain_yes_ramp_yes.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_cli_fixed.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_cli_loop.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_xml_fixed.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_foldtree.alfa.pdb'),
        Output('outputs/restrain_no_movemap_xml_loop_foldtree.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_cart.alfa.pdb'),
        Output('outputs/restrain_no_movemap_xml_loop_cart.alfa.pdb'),
        Output('outputs/restrain_yes_movemap_xml_loop_foldtree_cart.alfa.pdb'),
        Output('outputs/restrain_no_movemap_xml_loop_foldtree_cart.alfa.pdb'),
]

# Calculate RMSDs without superimposition.

def pick_designs(designs, terms):
    for design in designs:
        if all([x in design.slug for x in terms]):
            yield design

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

def parse_runtime(design):
    path = design.path.parent / f'{design.slug}.log'
    time_pattern = re.compile(r'protocols.jd2.JobDistributor: \d+ jobs considered, \d+ jobs attempted in (\d+) seconds')

    with path.open() as file:
        for line in file:
            time_match = time_pattern.match(line)
            if time_match:
                return int(time_match.group(1))

def parse_scoreterm(design, term):
    path = design.path.parent / f'{design.slug}.score.sc'

    with path.open() as file:
        _, header, body = file.readlines()

    header = header.split()
    body = body.split()

    try:
        i = header.index(term)
        return float(body[i])
    except ValueError:
        return None


def tabulate_rmsds(design):
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
    return pd.DataFrame(rows, columns=list(rows[0].keys()))

def tabulate_metrics(design):
    metrics = [
            ('runtime', parse_runtime(design)),
            ('total_score', parse_scoreterm(design, 'total_score')),
            ('coord_cst', parse_scoreterm(design, 'coordinate_constraint')),
            ('chainbreak', parse_scoreterm(design, 'chainbreak')),
            ('cart_bonded', parse_scoreterm(design, 'cart_bonded')),
    ]
    metrics = [(k,v) for k,v in metrics if v is not None]

    return pd.DataFrame(metrics, columns=['metric', 'value'])



args = docopt.docopt(__doc__)

# Define different sets of residues to compare.

bb = 'bb'  # Could also try using 'ca'
loop_a, loop_b = '26to51', '198to203'
loops = f'resnum {loop_a} {loop_b}'
selections = [ #
    ('Everything',    f'{bb}'),
    ('Chain A Loop',  f'{bb} resnum {loop_a}'),
    ('Chain B Loop',  f'{bb} resnum {loop_b}'),
    ('Scaffold-only', f'{bb} not {loops}'),
]

for design in pick_designs(designs, args['<keywords>']):
    print(design.title); print()

    rmsds = tabulate_rmsds(design)
    metrics = tabulate_metrics(design)

    print(rmsds); print()
    print(metrics); print()



