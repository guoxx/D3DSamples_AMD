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
// File: GenerateVPLs.hlsl
//
// HLSL file for the TiledLighting11 sample. VPL generation.
//--------------------------------------------------------------------------------------


#include "CommonHeader.h"


//-----------------------------------------------------------------------------------------
// Textures and Buffers
//-----------------------------------------------------------------------------------------
RWStructuredBuffer<float4>      g_VPLPositionBuffer                 : register( u0 );
RWStructuredBuffer<VPLData>     g_VPLDataBuffer                     : register( u1 );

Texture2D                       g_RSMDepthAtlas                     : register( t0 );
Texture2D                       g_RSMNormalAtlas                    : register( t1 );
Texture2D                       g_RSMDiffuseAtlas                   : register( t2 );

StructuredBuffer<float4x4>      g_invViewProjMatrices               : register( t3 );

#if ( SPOT_LIGHTS == 1 )
Buffer<float4> g_SpotLightBufferCenterAndRadius  : register( t4 );
Buffer<float4> g_SpotLightBufferColor            : register( t5 );
Buffer<float4> g_SpotLightBufferSpotParams       : register( t6 );
#else
Buffer<float4> g_PointLightBufferCenterAndRadius : register( t4 );
Buffer<float4> g_PointLightBufferColor           : register( t5 );
#endif


#if ( SPOT_LIGHTS == 1 )
#define RSM_SIZE        32
#else
#define RSM_SIZE        32
#endif

#define THREAD_SIZE     16
#define SAMPLE_WIDTH    ( RSM_SIZE / THREAD_SIZE )

[numthreads( THREAD_SIZE, THREAD_SIZE, 1 )]
void GenerateVPLsCS( uint3 globalIdx : SV_DispatchThreadID )
{
    uint2 uv00 = SAMPLE_WIDTH*globalIdx.xy;

#if ( SPOT_LIGHTS == 1 )
    uint lightIndex = SAMPLE_WIDTH*globalIdx.x / RSM_SIZE;
#else
    uint lightIndex = SAMPLE_WIDTH*globalIdx.y / RSM_SIZE;
    uint faceIndex = SAMPLE_WIDTH*globalIdx.x / RSM_SIZE;
#endif

    float3 color = 0;

    float3 normal = 0;

    float4 position = 1;

    uint2 uv = uv00;

    color = g_RSMDiffuseAtlas[ uv ].rgb;
    normal = (2*g_RSMNormalAtlas[ uv ].rgb)-1;

    float2 viewportUV = uv.xy;

    viewportUV.xy %= RSM_SIZE;

    float depth = g_RSMDepthAtlas[ uv ].r;

    float x = (2.0f * (((float)viewportUV.x + 0.5) / RSM_SIZE)) - 1.0;
    float y = (2.0f * -(((float)viewportUV.y + 0.5) / RSM_SIZE)) + 1.0;

    float4 screenSpacePos = float4( x, y, depth, 1.0 );

#if ( SPOT_LIGHTS == 1 )
    uint matrixIndex = lightIndex;
#else
    uint matrixIndex = (6*lightIndex)+faceIndex;
#endif

    position = mul( screenSpacePos, g_invViewProjMatrices[ matrixIndex ] );

    position.xyz /= position.w;


#if ( SPOT_LIGHTS == 1 )

    float4 SpotParams = g_SpotLightBufferSpotParams[lightIndex];
    float3 SpotLightDir;
    SpotLightDir.xy = SpotParams.xy;
    SpotLightDir.z = sqrt(1 - SpotLightDir.x*SpotLightDir.x - SpotLightDir.y*SpotLightDir.y);

    // the sign bit for cone angle is used to store the sign for the z component of the light dir
    SpotLightDir.z = (SpotParams.z > 0) ? SpotLightDir.z : -SpotLightDir.z;

    float4 sourceLightCentreAndRadius = g_SpotLightBufferCenterAndRadius[ lightIndex ];
    float3 lightPos = sourceLightCentreAndRadius.xyz - sourceLightCentreAndRadius.w*SpotLightDir;

#else

    float4 sourceLightCentreAndRadius = g_PointLightBufferCenterAndRadius[ lightIndex ];
    float3 lightPos = sourceLightCentreAndRadius.xyz;

#endif

    float3 sourceLightDir = position.xyz - lightPos;

    float lightDistance = length( sourceLightDir );

    {
        float fFalloff = 1.0 - length( sourceLightDir ) / sourceLightCentreAndRadius.w;

        color *= fFalloff;

        float3 normalizedColor = normalize( color );
        float dotR = dot( normalizedColor, float3( 1, 0, 0 ) );
        float dotG = dot( normalizedColor, float3( 0, 1, 0 ) );
        float dotB = dot( normalizedColor, float3( 0, 0, 1 ) );

        float threshold = g_fVPLColorThreshold;

        bool isInterestingColor = dotR > threshold || dotG > threshold || dotB > threshold;

        if ( isInterestingColor )
        {
            float4 positionAndRadius;

            float lightStrength = 1.0;

#if ( SPOT_LIGHTS == 1 )
            positionAndRadius.w = g_fVPLSpotRadius;
            lightStrength *= g_fVPLSpotStrength;
#else
            positionAndRadius.w = g_fVPLPointRadius;
            lightStrength *= g_fVPLPointStrength;
#endif

            positionAndRadius.xyz = position.xyz;

#if ( SPOT_LIGHTS == 1 )
            color = color * g_SpotLightBufferColor[ lightIndex ].rgb * lightStrength;
#else
            color = color * g_PointLightBufferColor[ lightIndex ].rgb * lightStrength;
#endif

            float colorStrength = length( color );
            if ( colorStrength > g_fVPLBrightnessThreshold )
            {
                VPLData data;

                data.Color = float4( color, 1 );
                data.Direction = float4( normal, 0 );

#if ( SPOT_LIGHTS == 1 )

                data.SourceLightDirection = float4( -SpotLightDir, 0 );
#else
                data.SourceLightDirection.xyz = normalize( -sourceLightDir );
                data.SourceLightDirection.w = 0;
#endif

                uint index = g_VPLPositionBuffer.IncrementCounter();

                g_VPLPositionBuffer[ index ] = positionAndRadius;
                g_VPLDataBuffer[ index ] = data;
            }
        }
    }
}

