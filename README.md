# custom-shaders-RedAlert3
Graphic improvements for this old dx9 game "Command Conquer Red Alert 3 " (2008) , based on hlsl code published in CnC3 Tiberium Wars MODSDK by Electronic Arts.

also with a little help from [https://github.com/lanyizi/DXDecompiler](https://github.com/lanyizi/DXDecompiler) (could be experimental)

the main project here is PBR (physical based render) shader. It should be used to replace Objects and Buildings shaders in the game 
(after compile! Don't try to let the game itself compile it, its compiler is too outdated. Use FXC.EXE from legacy microsoft direct x sdk. BUT 3dsmax requires uncompiled version. I recommand 3dsmax2023 with the exporter plugin in TOOLS folder)

Compiled+packed game-ready patch, download it here: (updated on April 22) https://www.moddb.com/mods/psysonic-omega/addons/pbr-shader-patch-v15#downloadsform

To compile your own shader: find "fxc.exe" in TOOLS folder (or from microsoft's official website), place it in the same folder with your FX and FXH files, open a command prompt here by type CMD on the path bar and use following command: ` fxc.exe /O2 /T fx_2_0 /Fo  OutputFileName.fxo   SourceFileName.fx  `

My latest and most complete implementation, with the ability of previewing near in-game result in 3dsmax. It was originally made for 
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/pointlightpreview.gif)
there are these adjustable parameters: (either get them from texture, or just a constant variable, or hardcoded)

diffuse color, ambient occlusion, insulent's reflectivity, fresnel effect f0, roughness, metalness, metal's reflection spectrum color, team color, emmisive color, emmisive blink frequncy, emmisive blink amplitude, shadow smoothing radius (is currently hardcoded to 2 for optimization),  transparency, and even a sub-surface scatter color for glass liquid container(currectly abandoned)

A special "compatible" version, for compatibility with textures from original game, is also added, a less accurate but more stylized PBR tweaking. The parameters mentioned above can be reconstructed via some hard coded functions and original game's textures.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/20240517113152.png)
you may notice, as the reflectivity increase, diffuse lights decreases according to law of conservation of energy. 
Fresnel effect (darker on verticle view angle) also becomes more obvious, and disappear again once the material is considered metallic. Metal is not supposed to cause diffuse reflection or fresnel effect either, all energy goes to specular.
if you want to edit the preview, such as adding or neglecting an in-game feature in 3dsmax, caution:
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/conditional.png)

ObjectWorkflow_Compatile.fx is a variant specially fine-tuned to match the original Red Alert 3 textures and artstyle while still maintaining all BRDF. NO texture edit is needed to use them!
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/old%20verson%20demo.png)
Left=original game shader, Right=new shader. As you may notice, the shadow's edge is also smoothed and anti-aliased.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/pcfshadow.png)
skybox is not needed, the shader will simulate a skybox with reflect vector and current roughness.

Here's also a video demo of my latest attempt to make a more "3d printing" effect when building up an object in the game, that has starry light rays descend from sky  and morph into a new triangle, one by one they build up a new structure. DX9 doesn't have geometry shader so i used multiple passes to handle different parts. (purely shadercontrolled, no new models needed) https://www.bilibili.com/video/BV1LZ421x7rJ/?

the original game used a very lasy way to shade the lights received from nearby point light sources (usually flame or laser VFX) which is a waste for such a nice feature. 
I implemented BRDF for all my point lights (the function was originally written for directional sunlight, but turns out even better for point light sources with correct decay multiplier)
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/single%20point%20light%2001.png )
dark environment with single point light. You can see the "mirror image" is blurred according to different surface roughness.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/single%20point%20lights%2002.png )
specular reflection caused by a weapon vfx, it makes the metallic surface seem more metallic
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/multi%20point%20lights%2002.png )
up to 8 nearby point lights can be received by a single drawcall / object per frame
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/multi%20point%20lights%2003.png )
Buildings with windows is a nice sample to observe. Notice that Fresnel effect and normal map also play big roles here.

as for the specular in BRDF (bi-directional reflection distribution function) i used a tricky approach: instead of calculating Half-way vector for every light source, I calculate the single Reflection vector based on View vector (yes the same vector that you use to sample skybox cube texture for envirnmental reflection) And compare the angle between it and other Light vectors. In fact i don't even compare the angles, but its Cosine, its function curve is pretty close to parabel. This can save a lot of computation power especially as point light count increases. 
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/helperfunctions.png )
Fresnel effect is also more obvious, though less realistic compared to the popular schlick approximation, i like the artstyle more.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/fresnel.png )

====(side project)====

I accidentially read across this [input semantic for pixel shader](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics#direct3d-9-vpos-and-direct3d-10-sv_position)  and realized, by using screen-space position as texture sampling coordinate, i can show the "protal to cosmos" visual effects, inspired by the "blade of no thought" vfx from genshin impact.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%2001.png ) 
this shader have one for objects and one for laser mesh. Named "starry" in this repo
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%20laser%2001.png) 
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%20laser%2002.png)
remember to register the starry sky texture in SCRAPEO so it can have standard annotation string address.



====(out dated contents below)====

The older PBR implementaions have three variants: "myPBR" for original game and most mods, "myPBR_g2yw" for Generals 2 mod, "myPBR_genevo" for Generals Evolution mod.
"3dsmax only" is for you to export the needed parameters in 3dsmax when making an w3x model file. It cannot be used in-game. The preview is crude (for now) you have to guess its in-game visuals. I'll implement a better preview in 3dsmax later.

Each has 10 (maybe more) global variables to adjust, you can tweak them to get the style fitting for your skirmish map. 
They all support up to 8 point lights (per mesh) all using microfacet BRDF to shade. You can see how the VFX cast lights on windows are way different from original game.

I will upload a few preview screenshots later.

terrain:  smooth shadow, RA2 style fog of war (register conflict occured, need further fixing)

laserhc:  laser now glow as team color, the "color emissive" in your VFX code can only control the brightness of this laser, not its color. However the laser texture's color can still influence final color, this color will be mixed with team color.

