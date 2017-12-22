#!/usr/bin/env bash
set -euo pipefail

pymol -qx \
    ../e38_lig_dimer.pdb \
    outputs/dimer_e38_lig_dimer.pdb \
    outputs/dimer_loops_38_e38_lig_dimer.pdb \
    outputs/dimer_loops_199_e38_lig_dimer.pdb \
    outputs/single_loop_e38_lig_dimer.pdb \
    outputs/backward_e38_lig_dimer.pdb \
    -d "as cartoon" \
    -d "color red, e38_lig_dimer and resi 1-38" \
