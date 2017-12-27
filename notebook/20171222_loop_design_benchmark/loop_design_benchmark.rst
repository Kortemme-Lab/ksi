*********************
Loop design benchmark
*********************

Having a loop design benchmark would be very helpful because it would allow us 
to parameterize PIP in a much more informed manner.  We've appreciated that for 
a long time, but I recently had some new thoughts about how we might make such 
a benchmark.  The realization I had was that we don't necessarily need to test 
the whole PIP pipeline, we just need to be able to test the individual 
algorithms that comprise PIP.  This isn't a very profound realization (in fact, 
it's bordering on obvious), but it still helped me think about things 
differently.

Brainstorming
=============
The inputs to the loop design problem are:

- A scaffold.
- An incorrect starting loop.
- One or more desired backbone coordinates.

A solution to the loop design problem comprises:

- A sequence.
- A model (optionally).

To benchmark a loop design algorithm, I need a data set that ties together 
these inputs and outputs.  

Someday it may be possible to just solve structures for a large number of 
randomly generated loops.  This would be an ideal dataset, because all 
sequences would be represented without bias.  I would be able to see which 
loops were structured and which weren't, and use that information to evaluate 
designs.  I would also be able to cluster the structured loops to find residues 
that often end up in the same place within a cluster.  I could use those 
residues as the "desired backbone coordinate" input to the design problem, then 
compare the sequences I get to those in the cluster.

Right now, the closest I can get to this ideal is to find homologous structured 
loops in the PDB.  More specifically, the benchmark I have in mind would go 
something like this:

- Choose a fold with a structured loop.
- Find other proteins with the same fold.
- Make a sequence logo for the loop by blasting the parts of those proteins 
  outside the loop (since my goal is to get a sequence logo, I wouldn't want to 
  bias that by including the loop in the blast query).
- Structurally cluster the known structures to find backbone coordinates that 
  are shared by most of them.  These are potential "given backbone coordinate" 
  inputs.
- Pick one (or more) of the known structures to be the scaffold.
- Make a "scrubbed" scaffold by altering or deleting the loop from the 
  scaffold, and maybe doing some other things to fudge the scaffold a bit.
- Provide a design algorithm with the "scrubbed" scaffold and the shared 
  backbone coordinates, then get from it any number of sequence and 
  (optionally) structure predictions.
- Score the algorithm based on how well the sequences and structures match the 
  known clusters.

The big difference between this and my ideal approach is that these sequences 
are biased by virtue of coming exclusively from functional proteins.  This 
means they may contain residues that are conserved for reasons other than 
structure, e.g. catalysis, pKa, binding specificity, allostery, etc.  They also 
won't contain any unstructured loops, so I'd need a completely different 
benchmark to test for structured sequences.  (There are ways to predict 
disorder just from sequence, so maybe I should try to incorporate those into 
PIP.  I doubt they'll catch everything, but they might catch some things.)

The thing that has caught me up when I've thought about this in the past is the 
incorrect starting loop conformation.  Because while you can imagine finding 
clusters of structured loops, it's a lot more difficult to find two or more 
clusters of structured loops that are related by a subtle set of mutations, 
such that you can use one cluster for scaffolds and the other cluster(s) to 
compare against.  Especially if you don't want those mutations to have any 
function other than structure.  Really, though, you don't need a natural 
starting point.  In fact, you probably want the residues in contact with the 
loop to come from one of the target structures, because they likely influence 
which sequences are allowed (You could imagine getting the perfect sequence 
logo for the "input" scaffold, but it not comparing very well to the sequence 
logo for the "target" scaffold.) 

With an artificial starting point (i.e. deleting the loop), you can easily tune 
how hard the design problem is:

- Delete more or fewer residues.
- Give more or fewer backbone coordinates.
- Allow more or fewer of the scaffold residues to design.
- Give more or fewer possibilities for the length of the loop.

(You can also tune difficulty by finding clusters with longer or more 
complicated loops.)


Criticisms and admonitions
--------------------------
- Is conservation due to structure or some aspect of function?

  This is a tough one; I'm not really sure how to get around it.  My thought is 
  that structured loops in binding interfaces are more likley than other loops 
  to be selected on the basis of structure, although certainly electrostatics 
  and H-bonding are important too.  Maybe I could do the design in the context 
  of the dimer, but that wouldn't leave a lot of room for the loop to move...

- The benchmark is too easy, because the residues contacting the loop encode 
  the correct structure and function.

  The idea is that the residues contacting the loop encode a sequence *logo*, 
  and challenge is to recapitulate that logo.  

  This is an common criticism of loop modeling benchmarks, so I want to think 
  more carefully about this criticism in light of the differences between the 
  two kinds of benchmark.  

  Loop modeling:

   - Input: sequence, scaffold
   - Output: structure

   - Keeping the context makes it a lot easier to get the structure, because 
     the context can leave a "groove" that the loop just needs to fit into.

   - The real-world use-case is homology modeling, and in that case you can't 
     expect your (probably not very good) model to have a nice groove for your 
     loop.

   - People try to account for these issues by fudging the scaffold: removing 
     sidechains, equilibrating in MD, superimposing takeoff and landing points 
     from other structures, and probably other things I'm not thinking of.

  Loop design:

   - Input: select loop coordinates, scaffold
   - Output: sequence logo, structure (optionally)

   - The context surely affects the sequence.  And in some positions (e.g.  
     H-bond donors/acceptors) it may give it away.  But it doesn't have the 
     same cooperativity that it does for the structure.  In other words, if 
     there's a groove for the loop to fit in, once you starting fitting some 
     parts of the loop into the groove, the rest of the loop really starts to 
     have nowhere else to go except the groove.  In contrast, if you're trying 
     to get the sequence, even if you know that there's an arginine here and a 
     glutamine there, you don't really know anything about the other positions.

     More than that, you can really frame the goal of the benchmark as trying 
     to get the sequence *from* the context.  (In contrast, I think the loop 
     modeling benchmark is more about trying to get the structure from the loop 
     itself.)  The sequence logo that we'll compare against comes from the  
     context, so in fact it's important to use the same context that gave rise 
     to that logo.  Of course, in reality the logo didn't come from just one 
     context, but you can approximate this by choosing relatively conserved 
     scaffolds with less conserved loops.

   - The real-world use-case is enzyme or interface design.  In both cases, 
     it's definitely the goal to leave the scaffold unchanged, and I think 
     people are usually successful at this (at least, the successful people 
     are).  So that may be a justification for not trying to scrub the 
     environment so hard.

- Ideally I'd find a scaffold that's very conserved with a structured loop 
  that's less conserved.  See the bullet points about loop design above for the 
  rationale.

- How can you benchmark for structured loops?

  For one thing, you would expect that an algorithm that accounts for loop 
  entropy should be able to do better, because it will be able to exclude more 
  extraneous sequences from its logo.

  In terms of designing another benchmark, predicting B-factors or order 
  parameters are the options that immediately come to mind.

- Most loops just have one key residue you need to get right.

  I'm not enunciating this objection quite right.  I don't think it's true that 
  most loops are entirely determined by just one residue (if that were the 
  case, structured loop design wouldn't be such a hard problem).  And as a 
  counter-example, the KSI loop is known to be influenced strongly by two 
  residues, and more weakly by several more.  There are shades of grey here.
  
  Maybe a better way to voice this objection is that although all the clusters 
  of everything have a lot of data, there are probably only a few fundamental 
  parameters that describe the data.  That invokes concerns of overfitting and 
  just having a benchmark that's less powerful than it seems.  Still, no matter 
  what the fundamental parameters are, the algorithms still need to get them 
  right.

- I should restrict the benchmark to loops where at least some (how many?) of 
  the wildtype sequences can be modeled correctly.

  Does this make the benchmark too easy?  To unrealistic?  To biased in favor 
  of rosetta, possibly to the detriment of other methods?  Only useful for 
  testing sampling methods, and not scoring methods?  Maybe this isn't such a 
  good idea.
