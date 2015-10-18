//
// Copyright 2014 ADVANCED MICRO DEVICES, INC.  All Rights Reserved.
//
// AMD is granting you permission to use this software and documentation (if
// any) (collectively, the “Materials”) pursuant to the terms and conditions
// of the Software License Agreement included with the Materials.  If you do
// not have a copy of the Software License Agreement, contact your AMD
// representative for a copy.
// You agree that you will not reverse engineer or decompile the Materials,
// in whole or in part, except as allowed by applicable law.
//
// WARRANTY DISCLAIMER: THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND.  AMD DISCLAIMS ALL WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY,
// INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, THAT THE SOFTWARE
// WILL RUN UNINTERRUPTED OR ERROR-FREE OR WARRANTIES ARISING FROM CUSTOM OF
// TRADE OR COURSE OF USAGE.  THE ENTIRE RISK ASSOCIATED WITH THE USE OF THE
// SOFTWARE IS ASSUMED BY YOU.
// Some jurisdictions do not allow the exclusion of implied warranties, so
// the above exclusion may not apply to You. 
// 
// LIMITATION OF LIABILITY AND INDEMNIFICATION:  AMD AND ITS LICENSORS WILL
// NOT, UNDER ANY CIRCUMSTANCES BE LIABLE TO YOU FOR ANY PUNITIVE, DIRECT,
// INCIDENTAL, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING FROM USE OF
// THE SOFTWARE OR THIS AGREEMENT EVEN IF AMD AND ITS LICENSORS HAVE BEEN
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.  
// In no event shall AMD's total liability to You for all damages, losses,
// and causes of action (whether in contract, tort (including negligence) or
// otherwise) exceed the amount of $100 USD.  You agree to defend, indemnify
// and hold harmless AMD and its licensors, and any of their directors,
// officers, employees, affiliates or agents from and against any and all
// loss, damage, liability and other expenses (including reasonable attorneys'
// fees), resulting from Your use of the Software or violation of the terms and
// conditions of this Agreement.  
//
// U.S. GOVERNMENT RESTRICTED RIGHTS: The Materials are provided with "RESTRICTED
// RIGHTS." Use, duplication, or disclosure by the Government is subject to the
// restrictions as set forth in FAR 52.227-14 and DFAR252.227-7013, et seq., or
// its successor.  Use of the Materials by the Government constitutes
// acknowledgement of AMD's proprietary rights in them.
// 
// EXPORT RESTRICTIONS: The Materials may be subject to export restrictions as
// stated in the Software License Agreement.
//

//--------------------------------------------------------------------------------------
// File: Deferred.hlsl
//
// HLSL file for the TiledLighting11 sample. G-Buffer rendering.
//--------------------------------------------------------------------------------------


#include "CommonHeader.h"


//-----------------------------------------------------------------------------------------
// Textures and Buffers
//-----------------------------------------------------------------------------------------
Texture2D              g_TxDiffuse     : register( t0 );
Texture2D              g_TxNormal      : register( t1 );

//--------------------------------------------------------------------------------------
// shader input/output structure
//--------------------------------------------------------------------------------------
struct VS_INPUT_SCENE
{
    float3 Position     : POSITION;  // vertex position
    float3 Normal       : NORMAL;    // vertex normal vector
    float2 TextureUV    : TEXCOORD0; // vertex texture coords
    float3 Tangent      : TANGENT;   // vertex tangent vector
};

struct VS_OUTPUT_SCENE
{
    float4 Position     : SV_POSITION; // vertex position
    float3 Normal       : NORMAL;      // vertex normal vector
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords
    float3 Tangent      : TEXCOORD1;   // vertex tangent vector
};

struct PS_OUTPUT
{
    float4 RT0 : SV_TARGET0;  // Diffuse
    float4 RT1 : SV_TARGET1;  // Normal
#if ( NUM_GBUFFER_RTS >= 3 )
    float4 RT2 : SV_TARGET2;  // Dummy
#endif
#if ( NUM_GBUFFER_RTS >= 4 )
    float4 RT3 : SV_TARGET3;  // Dummy
#endif
#if ( NUM_GBUFFER_RTS >= 5 )
    float4 RT4 : SV_TARGET4;  // Dummy
#endif
};


//--------------------------------------------------------------------------------------
// This shader transforms position, calculates world-space position, normal, 
// and tangent, and passes tex coords through to the pixel shader.
//--------------------------------------------------------------------------------------
VS_OUTPUT_SCENE RenderSceneToGBufferVS( VS_INPUT_SCENE Input )
{
    VS_OUTPUT_SCENE Output;
    
    // Transform the position from object space to homogeneous projection space
    float4 vWorldPos = mul( float4(Input.Position,1), g_mWorld );
    Output.Position = mul( vWorldPos, g_mViewProjection );

    // Normal and tangent in world space
    Output.Normal = mul( Input.Normal, (float3x3)g_mWorld );
    Output.Tangent = mul( Input.Tangent, (float3x3)g_mWorld );
    
    // Just copy the texture coordinate through
    Output.TextureUV = Input.TextureUV; 
    
    return Output;
}

//--------------------------------------------------------------------------------------
// This shader calculates diffuse and specular lighting for all lights.
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderSceneToGBufferPS( VS_OUTPUT_SCENE Input )
{ 
    PS_OUTPUT Output;

    // diffuse rgb, and spec mask in the alpha channel
    float4 DiffuseTex = g_TxDiffuse.Sample( g_Sampler, Input.TextureUV );

#if ( USE_ALPHA_TEST == 1 )
    float fAlpha = DiffuseTex.a;
    if( fAlpha < g_fAlphaTest ) discard;
#endif

    // get normal from normal map
    float3 vNorm = g_TxNormal.Sample( g_Sampler, Input.TextureUV ).xyz;
    vNorm *= 2;
    vNorm -= float3(1,1,1);
    
    // transform normal into world space
    float3 vBinorm = normalize( cross( Input.Normal, Input.Tangent ) );
    float3x3 BTNMatrix = float3x3( vBinorm, Input.Tangent, Input.Normal );
    vNorm = normalize(mul( vNorm, BTNMatrix ));

#if ( USE_ALPHA_TEST == 1 )
    Output.RT0 = DiffuseTex;
    Output.RT1 = float4(0.5*vNorm + 0.5, 0);
#else
    Output.RT0 = float4(DiffuseTex.rgb, 1);
    Output.RT1 = float4(0.5*vNorm + 0.5, DiffuseTex.a);
#endif

    // write dummy data to consume more bandwidth, 
    // for performance testing
#if ( NUM_GBUFFER_RTS >= 3 )
    Output.RT2 = float4(1,1,1,1);
#endif
#if ( NUM_GBUFFER_RTS >= 4 )
    Output.RT3 = float4(1,1,1,1);
#endif
#if ( NUM_GBUFFER_RTS >= 5 )
    Output.RT4 = float4(1,1,1,1);
#endif

    return Output;
}

