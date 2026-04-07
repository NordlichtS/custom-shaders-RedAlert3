// quantum vfx from honkai star rail

// give up on VERTEX POINT SPRITE
// is semi transparent, but fixed blend mode
// do not use screen buffer! mid low quality does not have it

/*

need constant: tex0, difftex, spm, int blendmode

no need: sunlight shadow, vertex normal

passes

p0 : main body
 vs no move
 ps with texture, crystal fresnel, 
 hc mix channel use shader array + int blendmode
 z write z test

p1 : shuffle front
 vs move X
 ps no tex ??? , do vpos Y random cutoff, maybe hc
 z test, but no z write, no stencil, backface cull

p2 : shuffle back (maybe not)
 vs move -x
 ps no tex , do vpos Y inverted cuftoff
 z test, no x write, no stencil, inv frontface cull 

NO  p3: point sprite or wire frame (not use) 
 ignore this for now, can cause z clipping
 we will use it together with wireframe
 but demo can have it just to show 

*/