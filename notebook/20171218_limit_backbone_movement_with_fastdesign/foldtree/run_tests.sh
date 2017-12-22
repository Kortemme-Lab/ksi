#!/usr/bin/env sh

ROSETTA=../../../rosetta
INPUTS=../../../inputs

mkdir -p outputs

function rosetta_scripts () {
    SLUG=$1; shift 1
    PREFIX=outputs/$SLUG
    titlebar $SLUG
    stdbuf -oL $ROSETTA/source/bin/rosetta_scripts.linuxclangrelease        \
        -database $ROSETTA/database                                         \
        -in:file:s $INPUTS/structures/e38_lig_dimer.pdb                     \
        -out:prefix ${PREFIX}_                                              \
        -out:no_nstruct_label                                               \
        -out:overwrite                                                      \
        -extra_res_fa $INPUTS/ligand/EQU.fa.params                          \
        "$@"                                                                |
        tee $PREFIX.log &
}

rosetta_scripts \
    dimer \
    -parser:protocol "perturb_manually.xml" \
    -parser:script_vars foldtree_file="$INPUTS/foldtree/dimer.foldtree" \
    -parser:script_vars perturb_angle=0 \
    -parser:script_vars resi=38 \

rosetta_scripts \
    dimer_loops_38 \
    -parser:protocol "perturb_manually.xml" \
    -parser:script_vars foldtree_file="$INPUTS/foldtree/dimer_loops.foldtree" \
    -parser:script_vars perturb_angle=0 \
    -parser:script_vars resi=38 \

rosetta_scripts \
    dimer_loops_199 \
    -parser:protocol "perturb_manually.xml" \
    -parser:script_vars foldtree_file="$INPUTS/foldtree/dimer_loops.foldtree" \
    -parser:script_vars perturb_angle=0 \
    -parser:script_vars resi=199 \

rosetta_scripts \
    single_loop \
    -parser:protocol "perturb_manually.xml" \
    -parser:script_vars foldtree_file="single_loop.foldtree" \
    -parser:script_vars perturb_angle=0 \
    -parser:script_vars resi=38 \

# This has an effect...
rosetta_scripts \
    backward \
    -parser:protocol "perturb_manually.xml" \
    -parser:script_vars foldtree_file="backward.foldtree" \
    -parser:script_vars perturb_angle=0 \
    -parser:script_vars resi=38 \

wait


