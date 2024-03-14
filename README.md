# custom-shaders-RedAlert3
Graphic improvements for this old dx9 game Command Conquer Red Alert 3 (2008) , based on hlsl code published in CnC3 Tiberium Wars MODSDK by Electronic Arts.

also with a little help from https://github.com/lanyizi/DXDecompiler (could be experimental)

the main project here is PBR (physical based render) shader. It should be used to replace Objects and Buildings shaders in the game (after compile!)

it has three variants: "myPBR" for original game and most mods, "myPBR_g2yw" for Generals 2 mod, "myPBR_genevo" for Generals Evolution mod.

Each has 10 (maybe more) global variables to adjust, you can tweak them to get the style fitting for your skirmish map. 
They all support up to 8 point lights (per mesh) all using microfacet BRDF to shade. You can see how the VFX cast lights on windows are way different from original game.

I will upload a few preview screenshots later.

terrain:  smooth shadow, RA2 style fog of war

laserhc:  laser now glow as faction color, but you need to set the laser texture to white/grey first, otherwise the colors will be mixed
