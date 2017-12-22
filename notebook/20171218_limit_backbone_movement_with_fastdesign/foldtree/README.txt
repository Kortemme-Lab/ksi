I want to figure out why the scaffold is moving, even though I set up a fold 
tree that shouldn't allow that.

The problem was that I wasn't constructing my fold trees correctly.  The ends 
of a loop need to be connected by a jump, otherwise the foldtree won't have a 
single root.
