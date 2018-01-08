#!/usr/bin/env bash
set -euo pipefail

pymol -qx \
    191650_000000_input.pdb.gz \
    outputs/191650_000000_input_*.pdb \
    -d "as cartoon" \
    -d "show sticks, resn EQU" \
    -d "show sticks, resi 198-201" \
    -d "sc" \
    -d "set_name 191650_000000_input, input" \


