#!/usr/bin/env sh

ROSETTA=../../rosetta
INPUTS=../../inputs
SCOREFXNS=$ROSETTA/database/scoring/weights

mkdir -p outputs

function fast_design () {
    SLUG=$1; shift 1
    PREFIX=outputs/$SLUG
    titlebar $SLUG

    # Remove the score file because otherwise rosetta will just keep adding 
    # lines to it, and the result will be uninterpretable if you add or remove 
    # terms from the score function.
    rm -f ${PREFIX}.score.sc

    # Note which version of the inputs files are being used for this run.
    git -C $INPUTS rev-parse HEAD >| ${PREFIX}_inputs_version.sha
    git -C $INPUTS diff >> ${PREFIX}_inputs_version.sha

    stdbuf -oL $ROSETTA/source/bin/rosetta_scripts.linuxclangrelease        \
        -database $ROSETTA/database                                         \
        -in:file:s alfa.pdb.gz                                              \
        -out:prefix ${PREFIX}.                                              \
        -out:no_nstruct_label                                               \
        -out:overwrite                                                      \
        -parser:script_vars wts_file=$SCOREFXNS/ref2015.wts                 \
        -parser:script_vars cst_file=$INPUTS/restraints/v4/glu.restraints   \
        -packing:resfile $INPUTS/resfile/v4/resfile                         \
        -extra_res_fa $INPUTS/ligand/EQU.fa.params                          \
        "$@"                                                                |
        tee $PREFIX.log &
}

# Run FastDesign with a number of different options.
fast_design \
    vanilla \
    -parser:protocol design_models.xml

fast_design \
    restrain_no \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords no

fast_design \
    restrain_none \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords

fast_design \
    restrain_yes \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords yes

wait

fast_design \
    restrain_yes_ramp_no \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords yes \
    -relax:ramp_constraints no

fast_design \
    restrain_yes_ramp_yes \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords yes \
    -relax:ramp_constraints yes

fast_design \
    restrain_yes_movemap_cli_fixed \
    -in:file:movemap fixed.movemap \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_yes_movemap_cli_loop \
    -in:file:movemap loop.movemap \
    -parser:protocol design_models.xml \
    -relax:constrain_relax_to_start_coords yes

wait

fast_design \
    restrain_yes_movemap_xml_fixed \
    -parser:protocol design_models_movemap_fixed.xml \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_yes_movemap_xml_loop \
    -parser:protocol design_models_movemap_loop.xml \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_yes_movemap_xml_loop_foldtree \
    -parser:protocol design_models_movemap_loop_foldtree.xml \
    -parser:script_vars foldtree_file=$INPUTS/foldtree/dimer_loops_2lig.foldtree \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_no_movemap_xml_loop_foldtree \
    -parser:protocol design_models_movemap_loop_foldtree.xml \
    -parser:script_vars foldtree_file=$INPUTS/foldtree/dimer_loops_2lig.foldtree \
    -relax:constrain_relax_to_start_coords no

wait

fast_design \
    restrain_yes_movemap_xml_loop_cart \
    -parser:protocol design_models_movemap_loop_cart.xml \
    -parser:script_vars wts_file=$SCOREFXNS/ref2015_cart.wts \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_no_movemap_xml_loop_cart \
    -parser:protocol design_models_movemap_loop_cart.xml \
    -parser:script_vars wts_file=$SCOREFXNS/ref2015_cart.wts \
    -relax:constrain_relax_to_start_coords no

fast_design \
    restrain_yes_movemap_xml_loop_foldtree_cart \
    -parser:protocol design_models_movemap_loop_foldtree_cart.xml \
    -parser:script_vars wts_file=$SCOREFXNS/ref2015_cart.wts \
    -parser:script_vars foldtree_file=$INPUTS/foldtree/dimer_loops_2lig.foldtree \
    -relax:constrain_relax_to_start_coords yes

fast_design \
    restrain_no_movemap_xml_loop_foldtree_cart \
    -parser:protocol design_models_movemap_loop_foldtree_cart.xml \
    -parser:script_vars wts_file=$SCOREFXNS/ref2015_cart.wts \
    -parser:script_vars foldtree_file=$INPUTS/foldtree/dimer_loops_2lig.foldtree \
    -relax:constrain_relax_to_start_coords no

# Also, FlxbbDesign vs FastDesign?
# 
# FlxbbDesign: source/src/protocols/flxbb/FlxbbDesign.cc
#   - "perform cycles of design and relax with filter"
#   - Seems like a more general framework for mixing the basic protocols.  
#     There's probably a paper that describes it better.

wait


