#!/usr/bin/env bash
set -euo pipefail

fork pymol -qx \
    alfa.pdb.gz \
    outputs/vanilla.alfa.pdb \
    outputs/restrain_no.alfa.pdb \
    outputs/restrain_none.alfa.pdb \
    outputs/restrain_yes.alfa.pdb \
    outputs/restrain_yes_ramp_no.alfa.pdb \
    outputs/restrain_yes_ramp_yes.alfa.pdb \
    outputs/restrain_yes_movemap_cli_fixed.alfa.pdb \
    outputs/restrain_yes_movemap_cli_loop.alfa.pdb \
    outputs/restrain_yes_movemap_xml_fixed.alfa.pdb \
    outputs/restrain_yes_movemap_xml_loop.alfa.pdb \
    outputs/restrain_yes_movemap_xml_loop_foldtree.alfa.pdb \
    outputs/restrain_no_movemap_xml_loop_foldtree.alfa.pdb \
    outputs/restrain_yes_movemap_xml_loop_cart.alfa.pdb \
    outputs/restrain_no_movemap_xml_loop_cart.alfa.pdb \
    outputs/restrain_yes_movemap_xml_loop_foldtree_cart.alfa.pdb \
    outputs/restrain_no_movemap_xml_loop_foldtree_cart.alfa.pdb \
    -d "alter alfa and resi 41-46, ss='L'" \
    -d "as cartoon" \
    -d "show sticks, resn EQU or resi 38" \
    -d "sc" \
    -d "disable all" \
    -d "enable alfa" \
    -d "set_view (\
     0.613317490,    0.542881012,   -0.573691189,\
     0.522295296,   -0.823623180,   -0.221021503,\
    -0.592495739,   -0.164079860,   -0.788686574,\
     0.000000000,    0.000000000, -183.438034058,\
    17.957942963,   75.661941528,   23.756927490,\
   144.623947144,  222.252120972,  -20.000000000 )"
    


