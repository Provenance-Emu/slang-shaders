#version 450

/*
   CRT - Guest - Advanced
   
   Copyright (C) 2018-2022 guest(r) - guest.r@gmail.com

   Incorporates many good ideas and suggestions from Dr. Venom.
   I would also like give thanks to many Libretro forums members for continuous feedback, suggestions and caring about the shader.
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
   
*/

layout(push_constant) uniform Push
{
	float TATE, IOS, OS, BLOOM, brightboost, brightboost1, csize, bsize1, warpX, warpY, glow, shadowMask, masksize,
	slotmask, slotmask1, slotwidth, double_slot, mcut, maskDark, maskLight, maskstr, mshift, mask_layout, mask_bloom;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float bloom;
	float halation;
	float slotms;
	float mclip;
	float mask_gamma;
	float gamma_out;
	float overscanX;
	float overscanY;	
	float intres;
	float c_shape;
	float barspeed;
	float barintensity;   
	float bardir;
	float sborder;
	float bloom_dist;
	float deconr;
	float decons;
	float addnoised;
	float noisetype;
	float noiseresd;
	float deconrr;
	float deconrg;
	float deconrb;
	float deconrry;
	float deconrgy;
	float deconrby;	
	float dctypex;
	float dctypey;
	float post_br;
	float maskboost;
	float smoothmask;
	float gamma_c;
	float m_glow;
} global;


#pragma parameter bogus_brightness "[ BRIGHTNESS SETTINGS ]:" 0.0 0.0 1.0 1.0

#pragma parameter m_glow "          Ordinary Glow / Magic Glow" 0.0 0.0 1.0 1.0

#pragma parameter glow "          Glow Strength" 0.08 -2.0 2.0 0.01
#define glow         params.glow     // Glow Strength

#pragma parameter bloom "          Bloom Strength" 0.0 -2.0 2.0 0.05
#define bloom         global.bloom     // bloom effect

#pragma parameter mask_bloom "          Mask Bloom" 0.0 0.0 2.0 0.05
#define mask_bloom         params.mask_bloom     // bloom effect

#pragma parameter bloom_dist "          Bloom Distribution" 0.0 0.0 3.0 0.05
#define bloom_dist         global.bloom_dist     // bloom effect distribution

#pragma parameter halation "          Halation Strength" 0.0 -2.0 2.0 0.025
#define halation         global.halation     // halation effect

#pragma parameter brightboost "          Bright Boost Dark Pixels" 1.40 0.25 10.0 0.05
#define brightboost  params.brightboost     // adjust brightness

#pragma parameter brightboost1 "          Bright Boost Bright Pixels" 1.10 0.25 3.00 0.025
#define brightboost1  params.brightboost1     // adjust brightness

#pragma parameter gamma_c "          Gamma correct" 1.0 0.50 2.0 0.025
#define gamma_c   global.gamma_c     // adjust brightness

#pragma parameter bogus_screen "[ SCREEN OPTIONS ]: " 0.0 0.0 1.0 1.0

#pragma parameter TATE "          TATE Mode" 0.0 0.0 1.0 1.0
#define TATE         params.TATE     // Screen orientation

#pragma parameter IOS "          Integer Scaling: Odd:Y, Even:'X'+Y" 0.0 0.0 4.0 1.0
#define IOS          params.IOS     // Smart Integer Scaling

#pragma parameter OS "          R. Bloom Overscan Mode" 1.0 0.0 2.0 1.0
#define OS           params.OS     // Do overscan

#pragma parameter BLOOM "          Raster bloom %" 0.0 0.0 20.0 1.0
#define BLOOM        params.BLOOM     // Bloom overscan percentage

#pragma parameter csize "          Corner Size" 0.0 0.0 0.25 0.005
#define csize        params.csize     // corner size

#pragma parameter bsize1 "          Border Size" 0.01 0.0 3.0 0.01
#define bsize1        params.bsize1     // border Size

#pragma parameter sborder "          Border Intensity" 0.75 0.25 2.0 0.05
#define sborder       global.sborder     // border intensity

#pragma parameter barspeed "          Hum Bar Speed" 50.0 5.0 200.0 1.0

#pragma parameter barintensity "          Hum Bar Intensity" 0.0 -1.0 1.0 0.01

#pragma parameter bardir "          Hum Bar Direction" 0.0 0.0 1.0 1.0

#pragma parameter warpX "          CurvatureX (default 0.03)" 0.0 0.0 0.25 0.01
#define warpX        params.warpX     // Curvature X

#pragma parameter warpY "          CurvatureY (default 0.04)" 0.0 0.0 0.25 0.01
#define warpY        params.warpY     // Curvature Y

#pragma parameter c_shape "          Curvature Shape" 0.25 0.05 0.60 0.05
#define c_shape        global.c_shape     // curvature shape

#pragma parameter overscanX "          Overscan X original pixels" 0.0 -200.0 200.0 1.0
#define overscanX        global.overscanX     // OverscanX pixels

#pragma parameter overscanY "          Overscan Y original pixels" 0.0 -200.0 200.0 1.0
#define overscanY        global.overscanY     // OverscanY pixels

#pragma parameter bogus_masks "[ CRT MASK OPTIONS ]: " 0.0 0.0 1.0 1.0

#pragma parameter shadowMask "          CRT Mask: 0:CGWG, 1-4:Lottes, 5-13:'Trinitron'" 0.0 -1.0 13.0 1.0
#define shadowMask   params.shadowMask     // Mask Style

#pragma parameter maskstr "          Mask Strength (0, 5-12)" 0.3 -0.5 1.0 0.025
#define maskstr         params.maskstr      // Mask Strength

#pragma parameter mcut "          Mask 5-12 Low Strength" 1.10 0.0 2.0 0.05
#define mcut         params.mcut      // Mask 5-12 dark color strength

#pragma parameter maskboost "          CRT Mask Boost" 1.0 1.0 3.0 0.05
#define maskboost     global.maskboost     // Mask Boost

#pragma parameter masksize "          CRT Mask Size" 1.0 1.0 4.0 1.0
#define masksize     params.masksize     // Mask Size

#pragma parameter maskDark "          Lottes maskDark" 0.5 0.0 2.0 0.05
#define maskDark     params.maskDark     // Dark "Phosphor"

#pragma parameter maskLight "          Lottes maskLight" 1.5 0.0 2.0 0.05
#define maskLight    params.maskLight     // Light "Phosphor"

#pragma parameter mshift "          Mask Shift/Stagger" 0.0 -8.0 8.0 0.5
#define mshift     params.mshift     // mask 'line' shift/stagger

#pragma parameter mask_layout "          Mask Layout: RGB or BGR (check LCD panel) " 0.0 0.0 1.0 1.0
#define mask_layout     params.mask_layout     // mask layout: RGB or BGR

#pragma parameter mask_gamma "          Mask gamma" 2.40 1.0 5.0 0.05
#define mask_gamma   global.mask_gamma     // Mask application gamma

#pragma parameter slotmask "          Slot Mask Strength Bright Pixels" 0.0 0.0 1.0 0.05
#define slotmask     params.slotmask

#pragma parameter slotmask1 "          Slot Mask Strength Dark Pixels" 0.0 0.0 1.0 0.05
#define slotmask1     params.slotmask1

#pragma parameter slotwidth "          Slot Mask Width" 2.0 1.0 8.0 1.0
#define slotwidth    params.slotwidth     // Slot Mask Width

#pragma parameter double_slot "          Slot Mask Height: 2x1 or 4x1..." 1.0 1.0 4.0 1.0
#define double_slot  params.double_slot     // Slot Mask Height

#pragma parameter slotms "          Slot Mask Size" 1.0 1.0 4.0 1.0
#define slotms  global.slotms     // Slot Mask Size

#pragma parameter mclip "          Keep Mask effect with clipping" 0.0 0.0 1.0 0.05
#define mclip  global.mclip     //

#pragma parameter smoothmask "          Smooth Masks in bright scanlines" 0.0 0.0 1.0 1.0
#define smoothmask  global.smoothmask

#pragma parameter gamma_out "          Gamma out" 2.4 1.0 5.0 0.05
#define gamma_out    global.gamma_out     // output gamma


#pragma parameter bogus_deconvergence11 "[ HORIZONTAL/VERTICAL DECONVERGENCE ]: " 0.0 0.0 1.0 1.0

#pragma parameter dctypex "          Deconvergence type X : 0.0 - static, other - dynamic" 0.0 0.0 0.75 0.05

#pragma parameter dctypey "          Deconvergence type Y : 0.0 - static, other - dynamic" 0.0 0.0 0.75 0.05

#pragma parameter deconrr "          Horizontal Deconvergence Red Range" 0.0 -15.0 15.0 0.25

#pragma parameter deconrg "          Horizontal Deconvergence Green Range" 0.0 -15.0 15.0 0.25

#pragma parameter deconrb "          Horizontal Deconvergence Blue Range" 0.0 -15.0 15.0 0.25

#pragma parameter deconrry "          Vertical Deconvergence Red Range" 0.0 -15.0 15.0 0.25

#pragma parameter deconrgy "          Vertical Deconvergence Green Range" 0.0 -15.0 15.0 0.25

#pragma parameter deconrby "          Vertical Deconvergence Blue Range" 0.0 -15.0 15.0 0.25
 
#pragma parameter decons "          Deconvergence Strength" 1.0 0.0 3.0 0.10

#pragma parameter addnoised "          Add Noise" 0.0 -1.0 1.0 0.02

#pragma parameter noiseresd "          Noise Resolution" 2.0 1.0 10.0 1.0

#pragma parameter noisetype "          Noise Type: Colored, Luma" 0.0 0.0 1.0 1.0

#pragma parameter post_br "          Post Brightness" 1.0 0.25 5.0 0.01


#define COMPAT_TEXTURE(c,d) texture(c,d)
#define TEX0 vTexCoord

#define OutputSize global.OutputSize
#define gl_FragCoord (vTexCoord * OutputSize.xy)

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord * 1.00001;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D LinearizePass;
layout(set = 0, binding = 3) uniform sampler2D AvgLumPass;
layout(set = 0, binding = 4) uniform sampler2D GlowPass;
layout(set = 0, binding = 5) uniform sampler2D BloomPass;
layout(set = 0, binding = 6) uniform sampler2D PrePass;
layout(set = 0, binding = 7) uniform sampler2D Source;

#define eps 1e-10 

// Shadow mask (1-4 from PD CRT Lottes shader).

vec3 Mask(vec2 pos, float mx, float mb)
{
	vec2 pos0 = pos;
	pos.y = floor(pos.y/masksize);
	float stagg_lvl = 1.0; if (fract(abs(mshift)) > 0.25 && abs(mshift) > 1.25) stagg_lvl = 2.0;
	float next_line = float(fract((pos.y/stagg_lvl)*0.5) > 0.25);
	pos0.x = (mshift > -0.25) ? (pos0.x + next_line * floor(mshift)) : (pos0.x + floor(pos.y / stagg_lvl) * floor(abs(mshift)));
	pos = floor(pos0/masksize);

	vec3 mask = vec3(maskDark, maskDark, maskDark);
	vec3 one = vec3(1.0);
	
	// brightness correcture masks 5-12
	float sm = 0.45; if(shadowMask == 8.0 || shadowMask == 11.0 || shadowMask == 13.0) sm = 0.7;
	float dark_compensate  = mix(max( clamp( mix (mcut, maskstr, mx),0.0, 1.0) - sm, 0.0) + 1.0, 1.0, mx);
	
	float mc = 1.0 - max(maskstr, 0.0);	
	
	// No mask
	if (shadowMask == -1.0)
	{
		mask = vec3(1.0);
	}       
	
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		pos.x = fract(pos.x*0.5);
		if (pos.x < 0.49) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
		else { mask.r = mc; mask.g = 1.0; mask.b = mc; }
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1.0)
	{
		float line = maskLight;
		float odd  = 0.0;

		if (fract(pos.x/6.0) < 0.49)
			odd = 1.0;
		if (fract((pos.y + odd)/2.0) < 0.49)
			line = maskDark;

		pos.x = fract(pos.x/3.0);
    
		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                    mask.b = maskLight;
		
		mask*=line;  
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = fract(pos.x/3.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                    mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*vec2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.3) mask.r = maskLight;
		else if (pos.x < 0.6) mask.g = maskLight;
		else                    mask.b = maskLight;
	}
	
	// Trinitron mask 5
	else if (shadowMask == 5.0)
	{
		mask = vec3(0.0);		
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.49)
		{	mask.r  = 1.0;
			mask.b  = 1.0;
		}
		else     mask.g = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Trinitron mask 6
	else if (shadowMask == 6.0)
	{
		mask = vec3(0.0);
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.3) mask.r = 1.0;
		else if (pos.x < 0.6) mask.g = 1.0;
		else                    mask.b = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}
	
	// BW Trinitron mask 7
	else if (shadowMask == 7.0)
	{
		mask = vec3(0.0);		
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.49)
		{	mask  = 0.0.xxx;
		}
		else     mask = 1.0.xxx;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// BW Trinitron mask 8
	else if (shadowMask == 8.0)
	{
		mask = vec3(0.0);
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.3) mask = 0.0.xxx;
		else if (pos.x < 0.6) mask = 1.0.xxx;
		else                  mask = 1.0.xxx;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Magenta - Green - Black mask
	else if (shadowMask == 9.0)
	{
		mask = vec3(0.0);
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.3) mask    = 0.0.xxx;
		else if (pos.x < 0.6) mask.rb = 1.0.xx;
		else                  mask.g  = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;	
	}  
	
	// RGBX
	else if (shadowMask == 10.0)
	{
		mask = vec3(0.0);
		pos.x = fract(pos.x * 0.25);
		if      (pos.x < 0.2)  mask  = 0.0.xxx;
		else if (pos.x < 0.4)  mask.r = 1.0;
		else if (pos.x < 0.7)  mask.g = 1.0;	
		else                   mask.b = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;		
	}  

	// 4k mask
	else if (shadowMask == 11.0)
	{
		mask = vec3(0.0);
		pos.x = fract(pos.x * 0.25);
		if      (pos.x < 0.2)  mask.r  = 1.0;
		else if (pos.x < 0.4)  mask.rg = 1.0.xx;
		else if (pos.x < 0.7)  mask.gb = 1.0.xx;	
		else                   mask.b  = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;		
	}     

	// RRGGBBX mask
	else if (shadowMask == 12.0)
	{
		mask = vec3(0.0);
		pos.x = floor(mod(pos.x,7.0));
		if      (pos.x < 0.5)  mask   = 0.0.xxx;
		else if (pos.x < 2.5)  mask.r = 1.0;
		else if (pos.x < 4.5)  mask.g = 1.0;	
		else                   mask.b = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}

	// 4k mask
	else
	{
		mask = vec3(0.0);
		pos.x = floor(mod(pos.x,6.0));
		if      (pos.x < 0.5)  mask   = 0.0.xxx;
		else if (pos.x < 1.5)  mask.r = 1.0;
		else if (pos.x < 2.5)  mask.rg = 1.0.xx;
		else if (pos.x < 3.5)  mask.rgb = 1.0.xxx;
		else if (pos.x < 4.5)  mask.gb = 1.0.xx;		
		else                   mask.b = 1.0;
		mask = clamp(mix( mix(one, mask, mcut), mix(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}
	
	float maskmin = min(min(mask.r,mask.g),mask.b);
	return (mask - maskmin) * (1.0 + (maskboost-1.0)*mb) + maskmin;
}

float SlotMask(vec2 pos, float m)
{
	if ((slotmask + slotmask1) == 0.0) return 1.0;
	else
	{
	if (shadowMask == 2.0 || shadowMask == 6.0) pos.x = pos.x + slotms;	
	pos = floor(pos/slotms);
	float mlen = slotwidth*2.0;
	float px = fract(pos.x/mlen);
	float py = floor(fract(pos.y/(2.0*double_slot))*2.0*double_slot);
	float slot_dark = mix(1.0-slotmask1, 1.0-slotmask, m);
	float slot = 1.0;
	if (py == 0.0 && px <  0.5) slot = slot_dark; else
	if (py == double_slot && px >= 0.5) slot = slot_dark;		
	
	return slot;
	}
}
 
vec2 Warp(vec2 pos)
{
	pos  = pos*2.0-1.0;    
	pos  = mix(pos, vec2(pos.x*inversesqrt(1.0-c_shape*pos.y*pos.y), pos.y*inversesqrt(1.0-c_shape*pos.x*pos.x)), vec2(warpX, warpY)/c_shape);
	return pos*0.5 + 0.5;
}

vec2 Overscan(vec2 pos, float dx, float dy){
	pos=pos*2.0-1.0;    
	pos*=vec2(dx,dy);
	return pos*0.5+0.5;
} 

float humbar(float pos)
{
	if (global.barintensity == 0.0) return 1.0; else
	{
		pos = (global.barintensity >= 0.0) ? pos : (1.0-pos);
		pos = fract(pos + mod(float(global.FrameCount),global.barspeed)/(global.barspeed-1.0));
		pos = (global.barintensity <  0.0) ? pos : (1.0-pos);	
		return (1.0-global.barintensity) + global.barintensity*pos;
	}	
}


float corner(vec2 pos) {
	vec2 b = vec2(bsize1, bsize1) *  vec2(1.0, OutputSize.x/OutputSize.y) * 0.05;
	pos = clamp(pos, 0.0, 1.0);
	pos = abs(2.0*(pos - 0.5));
	float csize1 = mix(400.0, 7.0,  pow(4.0*csize, 0.10));
	float crn = dot(pow(pos, csize1.xx), vec2(1.0, OutputSize.y/OutputSize.x));
	crn = (csize == 0.0) ? max(pos.x, pos.y) : pow(crn, 1.0/csize1);
	pos = max(pos, crn);
	vec2 res = (bsize1 == 0.0) ? 1.0.xx : mix(0.0.xx, 1.0.xx, smoothstep(1.0.xx, 1.0.xx-b, sqrt(pos)));
	res = pow(res, sborder.xx);	
	return sqrt(res.x*res.y);
}


vec3 plant (vec3 tar, float r)
{
	float t = max(max(tar.r,tar.g),tar.b) + 0.00001;
	return tar * r / t;
}

vec3 declip(vec3 c, float b)
{
	float m = max(max(c.r,c.g),c.b);
	if (m > b) c = c*b/m;
	return c;
}

float igc(float mc)
{
	return pow(mc, gamma_c);
}

// noise function:
// Dedicated to the public domain.
// If you want a real license, you may consider this MIT/BSD/CC0/WTFPL-licensed (take your pick).
// Adapted from ChuckNorris - shadertoy: https://www.shadertoy.com/view/XtK3Dz

vec3 noise(vec3 v){
    if (global.addnoised < 0.0) v.z = -global.addnoised; else v.z = mod(v.z,6001.0)/1753.0;
	// ensure reasonable range
    v = fract(v) + fract(v*1e4) + fract(v*1e-4);
    // seed
    v += vec3(0.12345, 0.6789, 0.314159);
    // more iterations => more random
    v = fract(v*dot(v, v)*123.456);
    v = fract(v*dot(v, v)*123.456);
	v = fract(v*dot(v, v)*123.456);
	v = fract(v*dot(v, v)*123.456);	
    return v;
} 

void fetch_pixel (inout vec3 c, inout vec3 b, vec2 coord, vec2 bcoord)
{
		float stepx = OutputSize.z;
		float stepy = OutputSize.w;
		
		float ds = global.decons;
				
		vec2 dx = vec2(stepx, 0.0);
		vec2 dy = vec2(0.0, stepy);		
		
		float posx = 2.0*coord.x - 1.0;
		float posy = 2.0*coord.y - 1.0;
		
		if (global.dctypex > 0.025)
		{
			posx = sign(posx)*pow(abs(posx), 1.05-global.dctypex);
			dx = posx * dx;
		}

		if (global.dctypey > 0.025)
		{

			posy = sign(posy)*pow(abs(posy), 1.05-global.dctypey);
			dy = posy * dy;
		}

		// if (global.dctypex > 0.025 || global.dctypey > 0.025) ds *= sqrt(posx*posx*sign(global.dctypex) + posy*posy*sign(global.dctypey));

		vec2 rc = global.deconrr * dx + global.deconrry*dy;
		vec2 gc = global.deconrg * dx + global.deconrgy*dy;
		vec2 bc = global.deconrb * dx + global.deconrby*dy;		

		float r1 = COMPAT_TEXTURE(Source, coord + rc).r;
		float g1 = COMPAT_TEXTURE(Source, coord + gc).g;
		float b1 = COMPAT_TEXTURE(Source, coord + bc).b;

		vec3 d = vec3(r1, g1, b1);
		c = clamp(mix(c, d, ds), 0.0, 1.0);
		
		r1 = COMPAT_TEXTURE(BloomPass, bcoord + rc).r;
		g1 = COMPAT_TEXTURE(BloomPass, bcoord + gc).g;
		b1 = COMPAT_TEXTURE(BloomPass, bcoord + bc).b;

		d = vec3(r1, g1, b1);
		b = clamp(mix(b, d, ds), 0.0, 1.0);
} 


void main()
{
	vec4 SourceSize = global.OriginalSize;
	
	float lum = COMPAT_TEXTURE(AvgLumPass, vec2(0.5,0.5)).a;
	
	float gamma_in = 1.0/COMPAT_TEXTURE(LinearizePass, vec2(0.25,0.25)).a;
	float intera = COMPAT_TEXTURE(LinearizePass, vec2(0.75,0.25)).a;
	bool interb  = (intera < 0.5);
	bool notate  = (TATE < 0.5);
	
	// Calculating texel coordinates
   
	vec2 texcoord = TEX0.xy;
	if (IOS > 0.0 && !interb){
		vec2 ofactor = OutputSize.xy/global.OriginalSize.xy;
		vec2 intfactor = (IOS < 2.5) ? floor(ofactor) : ceil(ofactor);
		vec2 diff = ofactor/intfactor;
		float scan = mix(diff.y, diff.x, TATE);
		texcoord = Overscan(texcoord, scan, scan);
		if (IOS == 1.0 || IOS == 3.0) texcoord = mix(vec2(TEX0.x, texcoord.y), vec2(texcoord.x, TEX0.y), TATE);
	}
   
	float factor  = 1.00 + (1.0-0.5*OS)*BLOOM/100.0 - lum*BLOOM/100.0;
	texcoord  = Overscan(texcoord, factor, factor);

	texcoord = Overscan(texcoord, (global.OriginalSize.x - overscanX)/global.OriginalSize.x, (global.OriginalSize.y - overscanY)/global.OriginalSize.y);

	vec2 pos1 = TEX0.xy;
	vec2 pos  = Warp(texcoord);
	vec2 pos0 = Warp(TEX0.xy);
	
	// color and bloom fetching
	vec3 color = COMPAT_TEXTURE(Source,pos1).rgb;
	vec3  Bloom = COMPAT_TEXTURE(BloomPass, pos).rgb;

if ((abs(global.deconrr) + abs(global.deconrry) + abs(global.deconrg) + abs(global.deconrgy) + abs(global.deconrb) + abs(global.deconrby)) > 0.2)
	fetch_pixel(color, Bloom, pos1, pos); // deconvergence
	
	float cm = igc(max(max(color.r,color.g),color.b));
	float mx1 = COMPAT_TEXTURE(Source, pos1     ).a;
	float colmx = max(mx1, cm);
	float w3 = min((cm + 0.0001) / (colmx + 0.0005), 1.0);
	
	vec2 dx = mix(vec2(0.001, 0.0), vec2(0.0, 0.001), TATE);
	float mx0 = COMPAT_TEXTURE(Source, pos1 - dx).a;
	float mx2 = COMPAT_TEXTURE(Source, pos1 + dx).a;
	float mxg = max(max(mx0,mx1),max(mx2,cm));
	float mx = pow(mxg, 1.40/gamma_in);

	// mask boost tweak
	
	dx = mix(vec2(global.OriginalSize.z, 0.0), vec2(0.0, global.OriginalSize.w), TATE) * 0.25;
	mx0 = COMPAT_TEXTURE(Source, pos1 - dx).a;
	mx2 = COMPAT_TEXTURE(Source, pos1 + dx).a;
	float mb = 1.0 - min(abs(mx0-mx2)/(0.5+mx1), 1.0);
	
	vec3 one = vec3(1.0);
	
	// Apply Mask
	
	vec3 orig1 = color;
	vec3 cmask = one;
	
	vec2 maskcoord = gl_FragCoord.yx * 1.000001;
	if (notate) maskcoord = maskcoord.yx;
	
	float smask = SlotMask(maskcoord, mx);	
	cmask*= Mask(maskcoord, mx, mb);

	if (mask_layout > 0.5) cmask = cmask.rbg;

	cmask*=smask;
	vec3 cmask1 = cmask;

	if (mask_bloom > 0.025)
	{
		float maxbl = max(max(max(Bloom.r,Bloom.g),Bloom.b), mxg);
		maxbl = maxbl * mix(1.0, 2.0-colmx, bloom_dist);
		cmask = max(min(cmask + maxbl*mask_bloom, 1.0), cmask);
	}
	
	color = pow(color, vec3(mask_gamma/gamma_in));
	color = color*cmask;
	color = min(color,1.0);
	color = pow(color, vec3(gamma_in/mask_gamma));

	cmask = min(cmask, 1.0);
	cmask1 = min(cmask1, 1.0);

	float bb = mix(brightboost, brightboost1, mx);
	if (interb) bb = (abs(intera-0.5)<0.1) ? pow(0.80*bb, 0.65) : pow(bb, 0.70);
	color*=bb;

	vec3  Ref = COMPAT_TEXTURE(LinearizePass, pos).rgb;
	vec3  Glow = COMPAT_TEXTURE(GlowPass, pos).rgb;
	float maxb = COMPAT_TEXTURE(BloomPass, pos).a;
	float vig  = COMPAT_TEXTURE(PrePass, clamp(pos, 0.0+0.5*global.OriginalSize.zw, 1.0-0.5*global.OriginalSize.zw)).a;

	vec3 Bloom1 = Bloom;

if (abs(bloom) > 0.025)
{
	if (bloom < -0.01) Bloom1 = plant(Bloom, maxb);
	Bloom1 = min(Bloom1*(orig1+color), max(0.5*(colmx + orig1 - color),0.001*Bloom1));
	Bloom1 = 0.5*(Bloom1 + mix(Bloom1, mix(colmx*orig1, Bloom1, 0.5), 1.0-color));
	Bloom1 = Bloom1 * mix(1.0, 2.0-colmx, bloom_dist);
	color = pow(pow(color, vec3(mask_gamma/gamma_in)) + abs(bloom) * pow(Bloom1, vec3(mask_gamma/gamma_in)), vec3(gamma_in/mask_gamma));
}

	color = min(color, mix(one, cmask1, mclip));

	if (!interb) color = declip(color, mix(1.0, w3, 0.6)); else w3 = 1.0;

	if (halation > 0.01) {
		Bloom = mix(0.5*(Bloom + Bloom*Bloom), 0.75*Bloom*Bloom, colmx);	
		color = color + 2.0*max((2.0*mix(maxb*maxb, maxb, colmx)-0.5*max(max(Ref.r,Ref.g),Ref.b)),0.25)*mix(1.0,w3,0.5*colmx)*mix(one,cmask,0.6)*Bloom*halation; }
	else
	if (halation < -0.01) {
		float mbl = max(max(Bloom.r,Bloom.g),Bloom.b);
		Bloom = plant(Bloom + Ref + orig1 + Bloom*Bloom*Bloom, min(mbl*mbl,0.75));
		color = color + 2.0*mix(1.0,w3,0.5*colmx)*mix(one,cmask,0.5)*Bloom*(-halation); }

	if (smoothmask > 0.5) { w3 = mix(1.0, w3, smoothstep(0.3, 0.6, mx1)); color = max(min(color/w3, 1.0)*w3, min(color,color*(1.0-w3))); }

	if (global.m_glow < 0.5) Glow = mix(Glow, 0.25*color, 0.7*colmx);
	else
	{ 
		vec3 gb = plant(orig1, 1.0);
		maxb = max(max(Glow.r,Glow.g),Glow.b);
		gb = mix(maxb*vec3(0.0, 0.0, 1.0), Glow, clamp(gb.r + gb.g - 0.375*gb.b,0.0,1.0)); 
		Glow = mix(0.75*Glow,5.0*plant(mix(gb,orig1, 0.5*sqrt(colmx)*abs(plant(Glow,1.0)-plant(orig1,1.0))), maxb), pow(colmx, 0.50/gamma_in));
		Glow = mix(Glow, 0.4*Glow, 1.0-colmx*colmx);
	}
	
	if (glow >= 0.0 && global.m_glow < 0.5) color = color + 0.5*Glow*glow; else { cmask*=cmask; cmask*=cmask; color = color + abs(glow)*cmask*Glow; }

	color = min(color, 1.0);
	
	color = pow(color, vec3(1.0/gamma_out));

	float rc = 0.6*sqrt(max(max(color.r, color.g), color.b))+0.4;
	
	if (abs(global.addnoised) > 0.01) 
	{
		vec3 noise0 = noise(vec3(floor(OutputSize.xy * vTexCoord / global.noiseresd), float(global.FrameCount)));
		if (global.noisetype < 0.5) color = mix(color, noise0, 0.25*abs(global.addnoised) * rc); 
		else color = min(color * mix(1.0, 1.5*noise0.x, 0.5*abs(global.addnoised)), 1.0);
	}
	
	FragColor = vec4(color*vig*humbar(mix(pos.y, pos.x, global.bardir))*global.post_br*corner(pos0), 1.0);
}
