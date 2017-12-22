***************************************
Limit backbone movement with FastDesign
***************************************

While I was putting together the demo project for AlgoSB, I became suspicious 
that the `-relax:constrain_relax_to_start_coords` option to FastDesign wasn't 
really doing anything.  Now I want to go back and test FastDesign more 
carefully and make sure it's behaving how I want it to.

I've also talked about this with Xingjie a couple times in the last few months, 
and he's given me somethings to try and/or think about, so that's mostly what 
I'll be doing.

Methods
=======
The following script runs FastDesign with a number of different options and 
saves all the results to `outputs/`::

   ./design_models.sh

Each run takes about 1h with extra rotamers, or about 5 min without.

The following script calculates backbone heavy-atom RMSDs both with and without 
superposition::

   ./calc_rmsds.py | tee fast_design_rmsds.txt

You can also look at the resulting models in pymol::

   ./open_models_in_pymol.sh
   
Results
=======

RMSDs
-----
.. literal-include:: fast_design_rmsds.txt

AlgoSB exercise
---------------
The reason I was suspicious of FastDesign in the first place is that I thought 
I was getting unacceptably large RMSDs for the FastDesign step when I was 
trying to put together an exercise for AlgoSB.  Note that I copied these files 
into the `algosb/` directory of this experiment, but didn't bother to rerun 
them.

I went back and calculated (by hand, in pymol) the backbone heavy-atom RMSDs 
between the models I generated for that exercise:

Model 1  Model 2   RMSD
=======  ========  =====
wt       "build"   0.208
wt       "design"  0.806
"build"  "design"  0.782

These numbers are higher than what I've been getting, but I'm at a bit of a 
loss to explain why.  I thought the problem was that I'd left the "yes" off the 
`-relax:constrain_relax_to_start_coords` option, but the difference in RMSD 
remained ever after that was corrected (and it turns out you don't need the 
"yes" anyways).

Another possibility is that the "build" model is just not as ideal as the wt 
model (especially given that it came from a simulation with severely reduced 
iterations), and in the context of a worse model the minimization was able to 
take us further away from its starting point.

`-in:file:movemap`
------------------
This option is mentioned in the documentation for the FastRelax app, but is not 
used by the FastDesign (or FastRelax) RosettaScripts mover.  This is one of 
the shitty things about rosetta: the interfaces are all so unpredictable in 
terms of which options they accept.  You really need to make sure that every 
option is really having the affect it purports to have.

You can tell that this option isn't doing what it should by looking at the RMSD 
results, but I also confirmed it by reading the code.  
`FastRelax::parse_my_tag()` creates a default-constructed  movemap and fills it 
in according to the "bondlength" and "bondangle" options.  Then a movemap 
factory is created either from an internal `<MoveMap>` tag via  
`protocols::rosetta_scripts::parse_movemap_factory_legacy()` or from an 
attribute via `core::select::movemap::parse_movemap_factory()`.  In the event 
that both are specified, the attribute takes precedence and a warning will be 
printed.  Presumably at some point the movemap factory alters the movemap.  
Neither the movemap nor the movemap factory consult `-in:file:movemap` ever.  

That said, when the movemap is specified in the RosettaScript itself, it has a 
noticeable effect.  Namely, the backbone pretty much stays in place everywhere 
except the loop (as expected) and the whole-dimer backbone heavy-atom RMSD 
drops from 0.6 to 0.2.

Note that the "fixed" model has a non-zero RMSD because I neglected to include 
the jump in the movemap.  This confused me at first, but I figured it out by 
superimposing the backbone heavy atoms of just one chain or the other in pymol 
(see command below) and getting and RMSD of 0.000::

   super restrain_yes_movemap_xml_fixed_e38_lig_dimer and chain B and name n+c+ca+o, e38_lig_dimer

Finally, it's worth noting that the "movemap" simulations were about twice as 
fast as their counterparts.  Compared to an average of 4450 sec/run for the 8 
simulations without a movemap (including the `movemap_cli` simulations), 
`movemap_loop` ran for 2453 sec and `movemap_fixed` ran for 2299 sec.

`-relax:constrain_relax_to_start_coords yes`
--------------------------------------------
From the RMSD results, it's clear that without this option, the whole protein 
rotates in space (not surprising given that internal coordinates are being 
minimized).  I believe I ran two simulations without start coord restraints, 
because the default value for this option is "false" (not documented, but 
confirmed in `options_rosetta.py`), so the `vanilla` and `restrain_no` 
simulations should be duplicates of each other.  These two simulations have 
initial RMSDs of 4.87Å and 1.27Å, respectively, indicating substantial movement 
of the backbone.  But after superimposing these models on the starting 
structure, the RMSDs go down to 0.74Å and 0.65Å (still higher than with start 
coord restraints, but not by much), indicating that really the backbone was 
just rotated and/or translated, but not deformed.

My conclusion is that it's probably best to restrain to start coords, but that 
if I decided not to for some reason, it wouldn't be hard to simply superimpose 
the FastDesigned model back onto the input model before continuing.

I also read the source code to figure out how the 
`-relax:constrain_relax_to_start_coords` options is (or isn't) interpreted by 
RosettaScripts.  (I was motivated by trying to explain a warning I was getting 
that ended up being due to me specifying the option twice by mistake.)  The 
source code for the FastDesign mover is located at::

    source/src/protocols/denovo_design/movers/FastDesign.cc

FastDesign inherits most of its functionality from FastRelax, which is located 
at::

    source/src/protocols/relax/FastRelax.cc
   
It looks like the "constrain to start coords" behavior is always initially set 
from the command line, see 
`RelaxProtocolBase::set_default_coordinate_settings()`.  It can also be set 
from `RelaxProtocolBase::constrain_relax_to_start_coords()`, but a search for 
"constrain_relax" in both FastRelax.cc and FastDesign.cc didn't turn up any 
code (there were some hits in comments).  So I'm inclined to believe that this 
option is directly read by the FastDesign protocol, and isn't affected by 
RosettaScripts at all.  (This matches the results I see from these simulations, 
but it's good to be sure.)

Based on the RMSD results, it appears that the following are equivalent:

- `-relax:constrain_relax_to_start_coords`
- `-relax:constrain_relax_to_start_coords yes`

I thought these might be different, based on my initial run of the AlgoSB 
exercise.  But in fact their equivalence is `documented behavior`__.

__ http://www.msg.ucsf.edu/local/programs/rosetta3.2.1_user_guide/command_options.html

`-relax:ramp_constraints`
-------------------------
I'm a little unsure what to make of the `-relax:ramp_constraints` option.  On 
the one hand, the one case where I set it to "yes" ended up with the worst E38 
restraint satisfaction (although none of the models had good satisfaction, 
because these models still have the D38 backbone).  On the other hand, one of 
the other 7 models I generated with backbone restraints ended up in the same 
rotamer, it's possible that this happened just by chance.

.. figure:: ramp_yes_vs_no.png

   Residue 38 in the initial structure (green), the ramp=no model (teal), and 
   the ramp=yes model (magenta).

The documentation is also `confusing`__. On one hand, it says the default is 
False.  On the other hand, it says "When explicitly set to false, do not ramp 
down constraints", which to me implies that the constraints would be ramped if 
this option wasn't specified.  So I'm not sure what the default behavior is.

__ https://www.rosettacommons.org/manuals/archive/rosetta3.4_user_guide/d6/d41/relax_commands.html

Finally, I'm not sure whether I'd expect better restraint satisfaction with or 
without ramping.  With ramping, the atoms in question can get far out of place 
in the beginning of the simulation.  This could result in those atoms getting 
trapped in a far-away local minimum, or in them finding their way around an 
energy barrier and ending up closer.

I think I need to run more simulations with each of these options, using the 
D38 structures (so the restraints can actually be satisfied).  I should also 
try to read the code to figure out what the default behavior is.

Foldtree and Cartesian minimization
-----------------------------------
Using a movemap limits which backbone residues can minimize, but the 
perturbations from any residues that *can* minimize will still propagate 
throughout the structure.  There's also a lever arm effect, so the positions 
furthest from the perturbation can move significantly.  (This isn't a big 
problem for KSI, since it's a relatively small protein).

There are two ways to eliminate this widespread movement.  The first is to 
setup a fold tree that localizes any perturbations to the regions being 
perturbed.  The second is to do Cartesian minimization.  Both of these 
approaches can introduce non-ideal bond lengths and angles in the backbone, so 
score terms need to be added to account for that.

It had to do some debugging to get the fold tree to work (see the `foldtree` 
directory).  Ultimately, I just had to be more careful to make sure that my 
fold trees had only one root node, and that all their edges were pointing in 
the right directions.

That said, there is one peculiarity I wasn't able to figure out.  If FastDesign 
is run without start coord restraints, the atoms outside the loop regions don't 
move at all.  However, if FastDesign is run *with* start coord restraints, the 
atoms outside the loop regions all move by about 0.006--0.010Å.  I get a 
similar results for the "fixed movemap" simulation, in which the movemap simply 
forbids backbone and jump movement.  Although I wish I knew why this was 
happening, I'm not really worried about it because 0.010Å is visually 
imperceptible and far below the resolution of a crystal structure.  Note that 
both foldtree simulations were run with exactly the same RosettaScript, the 
only difference was the value of the `-relax:constrain_relax_to_start_coords` 
option.  So it must be that those restraints are somehow responsible for the 
movement.

With the foldtree, the RMSD for the active site loop is 0.29Å with start coord 
restraints and 0.42Å without.  (I remember getting an RMSD closer to 0.5Å for a 
previous run without start coord restraints, so there is some wiggle here and 
0.42Å may be on the lower end.)  I'm not sure whether or not 

Cartesian minimization:

- Compare RMSD
- Compare runtime

Discussion
==========
I ran FastDesign with a lot of different options, but I did this just to get a 
better understanding of how FastDesign works and how I can control the amount 
of backbone movement that results.  It's tempting to make judgments about which 
options are better or worse, but I can't do that because I don't have a proper 
benchmark.

That said, my plan going forward is to use FastDesign with a movemap that only 
allows backbone movement in the loop and a fold tree that prevents that 
movement from propagating throughout the structure, much like the loop modeling 
simulations.  This is the most conservative option, and I think it's reasonable 
to be conservative in the absence of information on which method is best.  I 
also think it's not a good idea to move the whole backbone (in the absence of a 
compelling reason to do so).  Rosetta isn't good at getting subtle long-range 
interactions right, so I don't think there's any benefit to moving the backbone 
on the other side of the protein.

Again, without a benchmark I can't say whether or not it'd be better to 
restrain the backbone atoms to their start coordinates, but for now I think I'm 
not going to.  My concern is just that the 0.3Å loop RMSD I get when I apply 
start coord restraints might be too small to allow new rotamers to be explored.  
I also don't want to mess up the fragment-based loop structure I'm starting 
with, which is the concern with not restraining the backbone, but I think 
there's enough rigidity by virtue of sampling a pretty limited region of the 
protein that this is the lesser concern.

I don't know if the initial model is relaxed.  If it's not, maybe that could 
explain why I'm getting fairly large RMSDs (i.e. above the resolution of the 
crystal structure).

Notes
=====
- Can you have comments in the fold tree file?  This isn't documented, so I had 
  to go look at the source code to figure out.  The AtomTree mover from 
  RosettaScripts is really the 
  `protocols::protein_interface_design::movers::SetAtomTree` class.  
  `SetAtomTree::parse_my_tag()` reads the (possibly gzipped) file and redirects 
  it directly into newly instantiated FoldTree object using the `>>` operator.  
  Basically, the first word in the file must be "FOLD_TREE", and after that 
  every group of words must either start with "EDGE" or "JEDGE".  Comments are 
  not allowed, but words can be separated by spaces or newlines.

  This is another annoying thing about Rosetta.  All the config file formats 
  are so ad hoc.
