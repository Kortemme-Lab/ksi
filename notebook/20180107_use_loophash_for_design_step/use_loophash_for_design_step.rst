****************************
Use LoopHash for Design Step
****************************

While looking at the resfile for loop 200, I had second thoughts about 
designing it with FastDesign:

- I suspect that the sequence at any one position in the turn could be very 
  tightly coupled to the sequence and backbone structure at all the other 
  positions in the turn.  I don't really know how true this is, but it seemed 
  wrong to only design half the turn.  At the same time, I don't really trust 
  FastDesign to design the whole turn without messing it up, but LoopHash 
  should be more than capable.

- I suspect that each turn sequence may have it's own very distinct backbone 
  preference.  FastDesign can move the backbone, but it's a very small move and 
  I don't think it would be hard for it to find this sort of concerted change.  
  In contrast, LoopHash can basically exhaustively sample the space of known 
  4-residue turns.

My plan is to design both loops using FastDesign with a foldtree as I worked 
out in :expt:`limit_backbone_movement_with_fastdesign`, then to redesign loop 
200 using LoopHash afterwards.  The idea is to use FastDesign to introduce new 
interactions between the two loops (and also within loop 38, of course), then 
to use LoopHash to try to recapitulate those interactions as best as possible 
with a real turn.  It would probably be better to somehow do FastRelax and 
LoopHash simultaneously, but that sounds very difficult.
  
Methods
=======
I started with the first structure that was produced from the model building 
step of :expt:`run_pip_rebuild_loop_with_lhkic`, since I figured it would be 
representative.

I copied scripts from :expt:`limit_backbone_movement_with_fastdesign`, since it 
was my intention to build the model

How does LoopHash work?
-----------------------
There is a <LoopHash> RosettaScripts mover, but it didn't have any 
documentation, so I went to read the code to try to understand what it would 
do.

- Does it need MPI?  No.  
  
  I was worried about this because LoopHashMoverWrapper uses 
  FastRelax::batch_apply(), which seems like it just relaxes a bunch of things 
  (32 by default for LoopHash) at once.  So I skimmed through the code, and saw 
  that it's just using mundane for-loops.  I was left wondering how 
  batch_apply() is any faster or better than regular apply(), but that's a 
  question for another time.

- Does it design?  No.
  
  I'm worried about this because I just haven't seen the code to do it.  I'm 
  pretty sure that LoopHash has been used in ab-initio folding to design turns, 
  and it definitely knows the sequences of the fragments it's working with, so 
  certainly LoopHash can do design, but maybe this particular mover can't.

  LocalInserter_SimpleMin is ultimately responsible for inserting backbone 
  segments into the pose, and it does this by calling 
  BackboneSegment::apply_to_pose().  This method simply loops through all its 
  backbone torsions and calls Pose::set_{phi,psi,omega}() on each one.  It 
  conspicuously does not touch the sequence in anyway that I can see.

Results
=======
- The <LoopHash> mover cannot do design.  I confirmed this by reading the code 
  very carefully and by simply running the mover.  In fact, it's actually 
  discarding hits if they require torsions that don't match up with the current 
  sequence.  The bottom line: this mover is not useful for the purposes I had 
  in mind.

- For loop 200, LoopHash only finds 59 hits, and it discards 30 of those for 
  rama violations.  In the ends it only builds 10 loops (it's running up 
  against a "max" parameter, and I haven't looking into raising it), and 
  they're all the same kind of turn as the original loop.

  .. figure:: turns_both_views.png

     The input turn (green) and the 10 models built by LoopHash (all other 
     colors).  (a) Side view.  (b) Top view.  Every model seems to be more or 
     less a Type 1 turn (based on the direction the C=O bond in the middle 
     peptide is facing).

- Including fullatom mode (by providing the `relax_mover` and `nfullatom` 
  options) for some reason causes the structure to fly open.  The structures 
  look fine if I stop after centroid mode, though, so I don't see how this can 
  be due to the actual loop-hashing.
  
Discussion
==========
- I cannot use the <LoopHash> mover for design.

  It wouldn't be so hard to add some code to do this (I'm imagining an option 
  to LoopHashSampler and LocalInserter_SimpleMin that tells it whether or not 
  to copy the sequence into the pose) but I really feel like I'd be reinventing 
  the wheel.  I'd also be concerned that I'm getting so few hits for such a 
  common motif.

- I need to think a little more carefully about how to design this turn.  On 
  one hand, there are clear sequence preferences for turns.  On the other, this 
  turn doesn't seem to fit any of them, even though it does have a glycine.  
  (If it were a type 2 turn -- which it's not -- then the glycine would be 
  favored in the 3rd position, not the 2nd.)  So, can I design both positions?  
  Just one?  Neither?  While it would've been nice to use LoopHash to basically 
  skirt the whole issue (let the PDB decide!), probably the best thing will be 
  to understand this turn as best I can a make a decision accordingly.
