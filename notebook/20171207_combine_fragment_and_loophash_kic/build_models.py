#!/usr/bin/env python3

import sys
import pyrosetta
from pyrosetta import rosetta
from rosetta.protocols import loops
from rosetta.protocols import kinematic_closure as kic

rosetta.init(sys.argv[1:])

def load_frag_libs():
    frag_libs = rosetta.Vector1_FragSetOP()
    loops.read_loop_fragments(frag_libs)
    return frag_libs

def load_loophash_lib():
    loop_sizes = rosetta.core.get_integer_vector_option('lh:loopsizes')
    loophash_lib = LoopHashLibrary(loop_sizes)
    loophash_lib.load_mergeddb()
    return loophash_lib

def new_frag_kic_mover(frag_libs):
    perturber = kic.perturbers.FragmentPerturber(frag_libs)
    mover = kic.KicMover()
    mover.add_perturber(frag_perturber)
    return mover

def new_loophash_kic_mover(loophash_lib):
    perturber = kic.perturbers.LoopHashPerturberOP(loophash_lib)
    offsets = [x - 3 for x in loop_sizes if size > 5]
    pivot_picker = kic.pivot_picker.FixedOffsetsPivots(offsets)

    mover = kic.KicMover()
    mover.add_perturber(perturber)
    mover.set_pivot_picker(pivot_picker)
    return mover

design_loop = Loop(34, 44), Loop(199, 202)
no_design_loop = Loop(26, 51)

# This is a little inefficient, because I'm double sampling most of the loop.  
# Maybe I should make a pivot picker that avoids picking any pivots for fragKIC 
# that would be totally overridden by loophash kic.
#
# Actually, it's not that inefficient, because all the movers are applied 
# before accepting/rejecting.  It doesn't take long to make a KIC move.  What 
# takes a while is minimizing and repacking, and that still happens the same 
# number of times.
#
# A bigger concern is that the loophash mover won't totally shadow the fragment 
# kic mover.  In other words, if fragment KIC is being used to pick torsions 
# for the whole loop, probably some of the torsions in the region being 
# designed will come from the fragment mover, which of course if picking 
# torsions for the wrong sequence.
#
# I think then what I need is a new loop mover that makes fragment insertion 
# moves on either side of the loop, then closes the loop with loophash kic.  I 
# don't want to use fragment kic, because I want the ends on the two side to 
# move.



modeler = rosetta.protocols.loop_modeling.LoopModeler()
modeler.disable_build_stage()
# I might have to provide my own foldtree, since things might be confused by 
# having two overlapping loops.
#modeler.trust_fold_tree()
modeler.centroid_stage().add_mover(frag_kic)
modeler.fullatom_stage().add_mover(...)

