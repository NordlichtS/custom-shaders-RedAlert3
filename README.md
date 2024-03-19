# custom-shaders-RedAlert3
Graphic improvements for this old dx9 game "Command Conquer Red Alert 3 " (2008) , based on hlsl code published in CnC3 Tiberium Wars MODSDK by Electronic Arts.

also with a little help from https://github.com/lanyizi/DXDecompiler (could be experimental)

the main project here is PBR (physical based render) shader. It should be used to replace Objects and Buildings shaders in the game (after compile! 
Don't try to let the game itself compile it, its compiler is too outdated. Use FXC.EXE from legacy microsoft dx sdk.)

it has three variants: "myPBR" for original game and most mods, "myPBR_g2yw" for Generals 2 mod, "myPBR_genevo" for Generals Evolution mod.
"3dsmax only" is for you to export the needed parameters in 3dsmax when making an w3x model file. It cannot be used in-game. The preview is crude (for now) you have to guess its in-game visuals. I'll implement a better preview in 3dsmax later.

Each has 10 (maybe more) global variables to adjust, you can tweak them to get the style fitting for your skirmish map. 
They all support up to 8 point lights (per mesh) all using microfacet BRDF to shade. You can see how the VFX cast lights on windows are way different from original game.

I will upload a few preview screenshots later.

Compiled game-ready patch, download it here: (updated) https://www.moddb.com/mods/psysonic-omega/downloads/pbr-shader-patch-v12

terrain:  smooth shadow, RA2 style fog of war

laserhc:  laser now glow as team color, the "color emissive" in your VFX code can only control the brightness of this laser, not its color. However the laser texture's color can still influence final color, this color will be mixed with team color.
