#!/usr/bin/env bash
set -euo pipefail

fork pymol -qx \
    e38_lig_dimer.pdb \
    outputs/vanilla_e38_lig_dimer.pdb \
    outputs/restrain_no_e38_lig_dimer.pdb \
    outputs/restrain_none_e38_lig_dimer.pdb \
    outputs/restrain_yes_e38_lig_dimer.pdb \
    outputs/restrain_yes_ramp_no_e38_lig_dimer.pdb \
    outputs/restrain_yes_ramp_yes_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_cli_fixed_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_cli_loop_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_xml_fixed_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_xml_loop_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_xml_loop_foldtree_e38_lig_dimer.pdb \
    outputs/restrain_no_movemap_xml_loop_foldtree_e38_lig_dimer.pdb \
    outputs/restrain_yes_movemap_xml_loop_cart_e38_lig_dimer.pdb \
    outputs/restrain_no_movemap_xml_loop_cart_e38_lig_dimer.pdb \
    -d "as cartoon" \

