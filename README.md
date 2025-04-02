# custom-shaders-RedAlert3
Graphic improvements for this old dx9 game "Command Conquer Red Alert 3 " (2008) , based on hlsl code published in CnC3 Tiberium Wars MODSDK by Electronic Arts.

well looks like EA finally decided to be nice once and open-sourced all shader sourcecode from SAGE engine games, no more need to decompile and reverse engineer! I'll update some better examples soon. Check official source code here:  https://github.com/electronicarts/CnC_Modding_Support/tree/main/Red%20Alert%203/Shaders

old decompiler used to make our first prototype before EA open-sourced all shaders: https://github.com/lanyizi/DXDecompiler (experimental)

the main project here is PBR (physical based render) shader. It should be used to replace Objects and Buildings shaders in the game 
(after compile! Don't try to let the game itself compile it, its compiler is too outdated. Use FXC.EXE from legacy microsoft direct x sdk. BUT 3dsmax requires uncompiled version. I recommand 3dsmax2023 with the exporter plugin in TOOLS folder)

Compiled+packed game-ready patch, download it here: (updated on 2025.01.06) https://www.moddb.com/mods/psysonic-omega/addons

To compile your own shader: find "fxc.exe" in TOOLS folder (or from microsoft's official website), place it in the same folder with your FX and FXH files, open a command prompt here by type CMD on the path bar and use following command: ` fxc.exe /O2 /T fx_2_0 /Fo  OutputFileName.fxo   SourceFileName.fx  `

YOU CAN ALSO USE MY "COMPILEALL.BAT" FILE TO BATCH COMPILE ALL SHADERS AT ONE CLICK

My latest and most complete implementation, with the ability of previewing near in-game result in 3dsmax. It was originally made for the brilliant RiMian dev team
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/pointlightpreview.gif)
there are these adjustable parameters: (either get them from texture, or just a constant variable, or hardcoded)：
diffuse color, ambient occlusion, insulent's reflectivity, fresnel effect f0, roughness, metalness, metal's reflection spectrum color, team color, emmissive color, emmissive blink frequncy, shadow map smoothing + anti aliasing radius (is currently hardcoded for optimization), and more flexible transparency controls.

=== 2025.Jan. grand update ==================

The complete framework has been rewritten with more efficient functions and more perceise constant register assignment, see "FXFXH" folder. No more decompiled snippet will be used.

the "allow stealth" ability means to switch the render into a semi-transparent holographic feeling with edge color enchance, once it detects the opacity override is less than 100% . This is fully automatic, no need to code it into your mod.
(here should be a preview screenshot but i forgot to upload)

Here's also a magical shader i made that can show underground structures without breaking the ground. Because the game engine limits the ability to edit terrain while the game is running, it was impossible to make models like missile silo or mine pit before. Not any more !
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/underground1.gif)

It uses optical illusion without actually mess up the screen depth buffer, but the light/shadow/reflection calculations are all made as if they really locates underground.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/undergroundlight.gif)

You can compile the same source file (example here is PBR5-6-objects-PATCH.FX) into multiple variants of shaders, by commenting out some of these MACRO for conditional compiling, just like in C++ :
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/macro.png)


=== 2024 older content, kept for archival purpose ===================

=== all these previous features REMAIN working in the new version too =================

A special "compatible" version, for compatibility with textures from original game, is also added, a less accurate but more stylized PBR tweaking. The parameters mentioned above can be reconstructed via some hard coded functions and original game's textures.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/20240517113152.png)

you may notice, as the reflectivity increase, diffuse lights decreases according to law of conservation of energy. 
Fresnel effect (darker on verticle view angle) also becomes more obvious, and disappear again once the material is considered metallic. Metal is not supposed to cause diffuse reflection or fresnel effect either, all energy goes to specular.
if you want to edit the preview, such as adding or neglecting an in-game feature in 3dsmax, caution:
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/conditional.png)

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

as for the specular in BRDF (bi-directional reflection distribution function) i used a tricky approach: instead of calculating Half-way vector for every light source, I calculate the single Reflection vector based on View vector (yes the same vector that you use to sample skybox cube texture for envirnmental reflection) And compare the angle (actually cosine from dot product) between it and other Light vectors. This can save a lot of computation power especially as point light count increases. 
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/helperfunctions.png )
Fresnel effect is also more obvious, though less realistic compared to the popular schlick approximation, i like the artstyle more.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/fresnel.png )

===(side project)===

I accidentially read across this [input semantic for pixel shader](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics#direct3d-9-vpos-and-direct3d-10-sv_position)  and realized, by using screen-space position as texture sampling coordinate, i can show the "protal to cosmos" visual effects, inspired by the blade of no thought vfx from a certain anime game.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%2001.png ) 
this shader have one for objects and one for laser mesh. Named "starry" in this repo
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%20laser%2001.png) 
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/starry%20laser%2002.png)
remember to register the starry sky texture in SCRAPEO so it can have standard annotation string address.

=== slightly outdated content ===


ObjectWorkflow_Compatile.fx is a variant specially fine-tuned to match the original Red Alert 3 textures and artstyle while still maintaining all BRDF. NO texture edit is needed to use them!
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/old%20verson%20demo.png)
Left=original game shader, Right=new shader. As you may notice, the shadow's edge is also smoothed and anti-aliased.
![alt text](https://github.com/NordlichtS/custom-shaders-RedAlert3/blob/main/preview_images/pcfshadow.png)
skybox is not needed, the shader will simulate a skybox with reflect vector and current roughness.
