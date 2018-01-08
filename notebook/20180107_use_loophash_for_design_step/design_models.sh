#!/usr/bin/env sh

ROSETTA=../../rosetta/master
INPUTS=../../inputs
SCOREFXNS=$ROSETTA/database/scoring/weights
LOOPHASH_DB=../../data/pip/20180105_rebuild_lhkic_del1/loophash_db

mkdir -p outputs
PREFIX=outputs

# Remove the score file because otherwise rosetta will just keep adding 
# lines to it, and the result will be uninterpretable if you add or remove 
# terms from the score function.
rm -f ${PREFIX}/score.sc

# Note which version of the inputs files are being used for this run.
git -C $INPUTS rev-parse HEAD >| ${PREFIX}/inputs_version.sha
git -C $INPUTS diff >> ${PREFIX}/inputs_version.sha

stdbuf -oL $ROSETTA/source/bin/rosetta_scripts.linuxclangrelease                    \
    -database $ROSETTA/database                                                     \
    -in:file:s 191650_000000_input.pdb.gz                                           \
    -out:prefix ${PREFIX}/                                                          \
    -out:no_nstruct_label                                                           \
    -out:overwrite                                                                  \
    -parser:protocol loophash.xml                                                   \
    -parser:script_vars wts_file=$SCOREFXNS/ref2015.wts                             \
    -parser:script_vars cst_file=$INPUTS/restraints/v4/glu_del1.restraints          \
    -parser:script_vars foldtree_file=$INPUTS/foldtree/dimer_loops_del1.foldtree    \
    -parser:script_vars loop_start=198                                              \
    -parser:script_vars loop_stop=201                                               \
    -packing:resfile $INPUTS/resfile/v4/resfile_del1                                \
    -lh:db_path $LOOPHASH_DB                                                        \
    -extra_res_cen $INPUTS/ligand/EQU.cen.params                                    \
    -extra_res_fa $INPUTS/ligand/EQU.fa.params                                      \
    "$@"                                                                            |
    tee $PREFIX.log
