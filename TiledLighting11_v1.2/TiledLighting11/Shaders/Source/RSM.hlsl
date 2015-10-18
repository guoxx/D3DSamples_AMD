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
// File: RSM.hlsl
//
// HLSL file for the TiledLighting11 sample. RSM generation.
//--------------------------------------------------------------------------------------


#include "CommonHeader.h"


//-----------------------------------------------------------------------------------------
// Textures and Buffers
//-----------------------------------------------------------------------------------------
Texture2D              g_TxDiffuse     : register( t0 );

//--------------------------------------------------------------------------------------
// shader input/output structure
//--------------------------------------------------------------------------------------
struct VS_INPUT
{
    float3 Position     : POSITION;  // vertex position
    float3 Normal       : NORMAL;    // vertex normal vector
    float2 TextureUV    : TEXCOORD0; // vertex texture coords
    float3 Tangent      : TANGENT;   // vertex tangent vector
};

struct VS_OUTPUT
{
    float3 Normal       : NORMAL;      // vertex normal vector
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords
    float3 PositionWS   : TEXCOORD1;
    float4 Position     : SV_POSITION; // vertex position
};

struct PS_INPUT
{
    float3 Normal       : NORMAL;      // vertex normal vector
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords
    float3 PositionWS   : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4 Normal       : SV_TARGET0;
    float4 Diffuse      : SV_TARGET1;
};


VS_OUTPUT RSMVS( VS_INPUT Input )
{
    VS_OUTPUT Output;
    
    float4 vWorldPos = mul( float4(Input.Position,1), g_mWorld );

    Output.PositionWS = vWorldPos.xyz;
    Output.Position = mul( vWorldPos, g_mViewProjection );

    Output.Normal = mul( Input.Normal, (float3x3)g_mWorld );
    
    Output.TextureUV = Input.TextureUV;
    
    return Output;
}


PS_OUTPUT RSMPS( PS_INPUT Input )
{
    PS_OUTPUT Output = (PS_OUTPUT)0;

    Output.Normal.xyz = 0.5 * (1 + normalize( Input.Normal ));
    Output.Diffuse = g_TxDiffuse.Sample( g_Sampler, Input.TextureUV );
    Output.Diffuse.a = 1;
    
    return Output;
}
