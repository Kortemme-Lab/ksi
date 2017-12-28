*********************************
Combine fragment and loophash KIC
*********************************

A big conceptual weakness in PIP is that, during the model building step, the 
fragments being used to build the models are generated from the starting 
sequence, but the actual sequence of the models changes during the simulation.  
Basically, the models are sampled using the wrong fragments.

Xingjie developed the LoopHash KIC algorithm to address a similar problem.  The 
algorithm works by finding loop fragments that nearly connect the takeoff and 
landing points of the loop being designed, then inserts them using KIC.  It 
also keeps the sequences from the fragments, so the backbone torsions always 
match the current sequence.

The catch is that loophash KIC unavoidably designs every position in the loop.  
What I want to do is to find a way to use loophash KIC to sample the middle of 
the loop and fragment KIC to sample the ends (to allow the takeoff and landing 
points for loophash KIC to vary a bit).

I think this approach would be helpful for problems like KSI, where we really 
want to design a totaly new loop.  But I'm not sure it would be applicable to 
problems more like Cas9, where we have a really big loop, we want to design 
parts of it (not just "the middle"), and we want to stay as close to the 
original conformation as we can.

Brainstorming
=============
I've had a few ideas about how to do this:

- Make a composite perturber that uses the fragment perturber to sample some 
  torsions and the loophash perturber to sample others.

  The problem with this idea is that the loophash perturber wouldn't take into 
  account the fragment insertions when picking a loop to insert, because 
  loophash looks at the pose to determine the transformation between the 
  takeoff and landing points, but the fragment perturber only updates the 
  closure problem.  

  It wouldn't be hard to add a method to ClosureProblem that applies the 
  current perturbed torsions to the pose.  That would allow me to call the 
  fragment perturber, apply the unclosed torsions to a pose, then call the 
  loophash perturber.  But KIC currently banks on the assumption that the 
  perturbers don't actually touch the pose (in fact, they get a const Pose for 
  exactly that reason), so I would need to really think to make sure I wasn't 
  breaking anything by doing this.

- Combine fragment KIC and loophash KIC loop movers in one simulation.

  Specifically, my thought was to create two overlapping loops: a larger one 
  which would be sampled by fragment KIC and a smaller one in the middle that 
  would be sampled by loophash KIC.  

  The problem with this idea is that the torsions in the middle wold likely 
  still be influenced by fragment KIC, which is still wrong. 

  To get around this, I'd have to keep track of which torsions were perturbed 
  while sampling the outer loop, and be sure to perturb them again while 
  sampling the inner loop.  But that just feels fragile and inefficient.

- Make unclosed fragment insertion moves on the ends of the loop, and use 
  loophash to close the ends of the loop from the middle.

  The problem with this idea is that I don't want to rebuild the whole loop on 
  every move.  At that point I'm not doing Monte Carlo, I'm just guessing and 
  checking.  So I would need to pick a window, make a fragment insertion for 
  any residues in the window that are outside the "design area", then do 
  loophash KIC on any residues that are in that area.  I'd probably actually 
  want to run KIC over the whole window, to make sure the loop is closed 
  without having to worry about corner cases like "were there fewer than 3 
  residues in the loophash area?"  Actually, I don't think that would be so 
  hard.  The end effect is pretty similar to the composite perturber idea, but 
  wouldn't require me to hack on the KIC machinery at all.

  I would have to write a new mover in C++, but I could probably prototype it 
  in python first.  And once I have a new mover in C++, I could stay in 
  RosettaScripts for now.

- Just use loophash KIC, and keep the region outside it frozen.

  This is a "just get it working" idea.  It would be easy to do, and it isn't 
  conceptually problematic in the ways that fragment KIC is (specifically that 
  the sampling is wrong and the validation is circular).  It isn't very 
  realistic to have the ends of the loop frozen, but this is mitigated by the 
  fact that the ends will move in the design and validation steps.  With the 
  smaller loop, I could also rebuild the whole thing from scratch.  That could 
  be helpful for KSI, where we really want to create a totally different loop 
  conformation.

I think it's worth taking a shot at that third idea, but going back to loophash 
if I run into too many problems.
