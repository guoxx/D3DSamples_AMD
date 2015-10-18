//
// Copyright 2014 ADVANCED MICRO DEVICES, INC.  All Rights Reserved.
//
// AMD is granting you permission to use this software and documentation (if
// any) (collectively, the �Materials�) pursuant to the terms and conditions
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
// File: ForwardPlus11DebugDraw.hlsl
//
// HLSL file for the ForwardPlus11 sample. Debug drawing.
//--------------------------------------------------------------------------------------


#include "ForwardPlus11Common.hlsl"

// disable warning: pow(f, e) will not work for negative f
#pragma warning( disable : 3571 )

//-----------------------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------------------
static const float4 kRadarColors[14] = 
{
    {0,0.9255,0.9255,1},   // cyan
    {0,0.62745,0.9647,1},  // light blue
    {0,0,0.9647,1},        // blue
    {0,1,0,1},             // bright green
    {0,0.7843,0,1},        // green
    {0,0.5647,0,1},        // dark green
    {1,1,0,1},             // yellow
    {0.90588,0.75294,0,1}, // yellow-orange
    {1,0.5647,0,1},        // orange
    {1,0,0,1},             // bright red
    {0.8392,0,0,1},        // red
    {0.75294,0,0,1},       // dark red
    {1,0,1,1},             // magenta
    {0.6,0.3333,0.7882,1}, // purple
};

//-----------------------------------------------------------------------------------------
// Buffers
//-----------------------------------------------------------------------------------------

// Save two slots for CDXUTSDKMesh diffuse and normal, 
// so start with the third slot, t2
Buffer<float4> g_PointLightBufferCenterAndRadius : register( t2 );
Buffer<float4> g_PointLightBufferColor           : register( t3 );
Buffer<float4> g_SpotLightBufferCenterAndRadius  : register( t4 );
Buffer<float4> g_SpotLightBufferColor            : register( t5 );
Buffer<float4> g_SpotLightBufferSpotParams       : register( t6 );
Buffer<uint>   g_PerTileLightIndexBuffer         : register( t7 );

Buffer<float4> g_SpotLightBufferSpotMatrices     : register( t8 );

//-----------------------------------------------------------------------------------------
// Helper functions
//-----------------------------------------------------------------------------------------
uint GetNumLightsInThisTile(uint nTileIndex)
{
    uint nNumLightsInThisTile = 0;
    uint nIndex = g_uMaxNumLightsPerTile*nTileIndex;
    uint nNextLightIndex = g_PerTileLightIndexBuffer[nIndex];

    // count point lights
    while ( nNextLightIndex != LIGHT_INDEX_BUFFER_SENTINEL )
    {
        nNumLightsInThisTile++;
        nIndex++;
        nNextLightIndex = g_PerTileLightIndexBuffer[nIndex];
    }

    // move past the first sentinel to get to the spot lights
    nIndex++;
    nNextLightIndex = g_PerTileLightIndexBuffer[nIndex];

    // count spot lights
    while ( nNextLightIndex != LIGHT_INDEX_BUFFER_SENTINEL )
    {
        nNumLightsInThisTile++;
        nIndex++;
        nNextLightIndex = g_PerTileLightIndexBuffer[nIndex];
    }

    return nNumLightsInThisTile;
}

//--------------------------------------------------------------------------------------
// shader input/output structure
//--------------------------------------------------------------------------------------
struct VS_INPUT_POS_TEX
{
    float3 Position     : POSITION;    // vertex position 
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords 
};

struct VS_OUTPUT_POS_TEX
{
    float4 Position     : SV_POSITION; // vertex position
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords 
};

struct VS_INPUT_DRAW_POINT_LIGHTS
{
    float3 Position     : POSITION;    // vertex position 
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords 
    uint   InstanceID   : SV_InstanceID;
};

struct VS_OUTPUT_DRAW_POINT_LIGHTS
{
    float4 Position     : SV_POSITION; // vertex position
    float4 Color        : COLOR0;      // vertex color
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords 
};

struct VS_INPUT_DRAW_SPOT_LIGHTS
{
    float3 Position     : POSITION;    // vertex position
    float3 Normal       : NORMAL;      // vertex normal vector
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords
    uint   InstanceID   : SV_InstanceID;
};

struct VS_OUTPUT_DRAW_SPOT_LIGHTS
{
    float4 Position     : SV_POSITION; // vertex position
    float3 Normal       : NORMAL;      // vertex normal vector
    float4 Color        : COLOR0;      // vertex color
    float2 TextureUV    : TEXCOORD0;   // vertex texture coords 
    float3 PositionWS   : TEXCOORD1;   // vertex position (world space)
};

struct VS_OUTPUT_POSITION_ONLY
{
    float4 Position     : SV_POSITION; // vertex position 
};

//--------------------------------------------------------------------------------------
// This shader reads from the light buffer to create a screen-facing quad
// at each light position.
//--------------------------------------------------------------------------------------
VS_OUTPUT_DRAW_POINT_LIGHTS DebugDrawPointLightsVS( VS_INPUT_DRAW_POINT_LIGHTS Input )
{
    VS_OUTPUT_DRAW_POINT_LIGHTS Output;

    // get the light position from the light buffer (this will be the quad center)
    float4 LightPositionViewSpace = mul( float4(g_PointLightBufferCenterAndRadius[Input.InstanceID].xyz,1), g_mWorldView );

    // move from center to corner in view space (to make a screen-facing quad)
    LightPositionViewSpace.xy = LightPositionViewSpace.xy + Input.Position.xy;

    // transform the position from view space to homogeneous projection space
    Output.Position = mul( LightPositionViewSpace, g_mProjection );

    // pass through color from the light buffer and tex coords from the vert data
    Output.Color = g_PointLightBufferColor[Input.InstanceID];
    Output.TextureUV = Input.TextureUV;
    return Output;
}

//--------------------------------------------------------------------------------------
// This shader reads from the light buffer to create a screen-facing quad
// at each light position.
//--------------------------------------------------------------------------------------
VS_OUTPUT_DRAW_SPOT_LIGHTS DebugDrawSpotLightsVS( VS_INPUT_DRAW_SPOT_LIGHTS Input )
{
    VS_OUTPUT_DRAW_SPOT_LIGHTS Output;

    float4 BoundingSphereCenterAndRadius = g_SpotLightBufferCenterAndRadius[Input.InstanceID];
    float4 SpotParams = g_SpotLightBufferSpotParams[Input.InstanceID];

    // reconstruct z component of the light dir from x and y
    float3 SpotLightDir;
    SpotLightDir.xy = SpotParams.xy;
    SpotLightDir.z = sqrt(1 - SpotLightDir.x*SpotLightDir.x - SpotLightDir.y*SpotLightDir.y);

    // the sign bit for cone angle is used to store the sign for the z component of the light dir
    SpotLightDir.z = (SpotParams.z > 0) ? SpotLightDir.z : -SpotLightDir.z;

    // calculate the light position from the bounding sphere (we know the top of the cone is 
    // r_bounding_sphere units away from the bounding sphere center along the negated light direction)
    float3 LightPosition = BoundingSphereCenterAndRadius.xyz - BoundingSphereCenterAndRadius.w*SpotLightDir;

    // rotate the light to point along the light direction vector
    float4x4 LightRotation = { g_SpotLightBufferSpotMatrices[4*Input.InstanceID], 
                               g_SpotLightBufferSpotMatrices[4*Input.InstanceID+1],
                               g_SpotLightBufferSpotMatrices[4*Input.InstanceID+2],
                               g_SpotLightBufferSpotMatrices[4*Input.InstanceID+3] };
    float3 VertexPosition = mul( Input.Position, (float3x3)LightRotation ) + LightPosition;
    float3 VertexNormal = mul( Input.Normal, (float3x3)LightRotation );

    // transform the position to homogeneous projection space
    Output.Position = mul( float4(VertexPosition,1), g_mWorldViewProjection );

    // position and normal in world space
    Output.PositionWS = mul( VertexPosition, (float3x3)g_mWorld );
    Output.Normal = mul( VertexNormal, (float3x3)g_mWorld );

    // pass through color from the light buffer and tex coords from the vert data
    Output.Color = g_SpotLightBufferColor[Input.InstanceID];
    Output.TextureUV = Input.TextureUV;
    return Output;
}

//--------------------------------------------------------------------------------------
// This shader creates a procedural texture to visualize the point lights.
//--------------------------------------------------------------------------------------
float4 DebugDrawPointLightsPS( VS_OUTPUT_DRAW_POINT_LIGHTS Input ) : SV_TARGET
{
    float fRad = 0.5f;
    float2 Crd = Input.TextureUV - float2(fRad, fRad);
    float fCrdLength = length(Crd);

    // early out if outside the circle
    if( fCrdLength > fRad ) discard;

    // use pow function to make a point light visualization
    float x = ( 1.f-fCrdLength/fRad );
    return (0.5f*pow(x,5.f)*Input.Color + 2.f*pow(x,20.f));
}

//--------------------------------------------------------------------------------------
// This shader creates a procedural texture to visualize the spot lights.
//--------------------------------------------------------------------------------------
float4 DebugDrawSpotLightsPS( VS_OUTPUT_DRAW_SPOT_LIGHTS Input ) : SV_TARGET
{
    float3 vViewDir = normalize( g_vCameraPos - Input.PositionWS );
    float3 vNormal = normalize(Input.Normal);
    float fEdgeFade = dot(vViewDir,vNormal);
    fEdgeFade = saturate(fEdgeFade*fEdgeFade);
    return fEdgeFade*Input.Color;
}

//--------------------------------------------------------------------------------------
// This shader visualizes the number of lights per tile, in grayscale.
//--------------------------------------------------------------------------------------
float4 DebugDrawNumLightsPerTileGrayscalePS( VS_OUTPUT_POSITION_ONLY Input ) : SV_TARGET
{
    uint nTileIndex = GetTileIndex(Input.Position.xy);
    uint nNumLightsInThisTile = GetNumLightsInThisTile(nTileIndex);
    float fPercentOfMax = (float)nNumLightsInThisTile / (float)g_uMaxNumLightsPerTile;
    return float4(fPercentOfMax, fPercentOfMax, fPercentOfMax, 1.0f);
}

//--------------------------------------------------------------------------------------
// This shader visualizes the number of lights per tile, using weather radar colors.
//--------------------------------------------------------------------------------------
float4 DebugDrawNumLightsPerTileRadarColorsPS( VS_OUTPUT_POSITION_ONLY Input ) : SV_TARGET
{
    uint nTileIndex = GetTileIndex(Input.Position.xy);
    uint nNumLightsInThisTile = GetNumLightsInThisTile(nTileIndex);

    // black for no lights
    if( nNumLightsInThisTile == 0 ) return float4(0,0,0,1);
    // light purple for reaching the max
    else if( nNumLightsInThisTile == g_uMaxNumLightsPerTile ) return float4(0.847,0.745,0.921,1);
    // white for going over the max
    else if ( nNumLightsInThisTile > g_uMaxNumLightsPerTile ) return float4(1,1,1,1);
    // else use weather radar colors
    else
    {
        // use a log scale to provide more detail when the number of lights is smaller

        // want to find the base b such that the logb of g_uMaxNumLightsPerTile is 14
        // (because we have 14 radar colors)
        float fLogBase = exp2(0.07142857f*log2((float)g_uMaxNumLightsPerTile));

        // change of base
        // logb(x) = log2(x) / log2(b)
        uint nColorIndex = floor(log2((float)nNumLightsInThisTile) / log2(fLogBase));
        return kRadarColors[nColorIndex];
    }
}

//--------------------------------------------------------------------------------------
// This shader converts screen space position xy into homogeneous projection space 
// and passes through the tex coords.
//--------------------------------------------------------------------------------------
VS_OUTPUT_POS_TEX DebugDrawLegendForNumLightsPerTileVS( VS_INPUT_POS_TEX Input )
{
    VS_OUTPUT_POS_TEX Output;

    // convert from screen space to homogeneous projection space
    Output.Position.x =  2.0f * ( Input.Position.x / (float)g_uWindowWidth )  - 1.0f;
    Output.Position.y = -2.0f * ( Input.Position.y / (float)g_uWindowHeight ) + 1.0f;
    Output.Position.z = 0.0f;
    Output.Position.w = 1.0f;

    // pass through
    Output.TextureUV = Input.TextureUV;

    return Output;
}

//--------------------------------------------------------------------------------------
// This shader creates a procedural texture for a grayscale gradient, for use as 
// a legend for the grayscale lights-per-tile visualization.
//--------------------------------------------------------------------------------------
float4 DebugDrawLegendForNumLightsPerTileGrayscalePS( VS_OUTPUT_POS_TEX Input ) : SV_TARGET
{
    float fGradVal = Input.TextureUV.y;
    return float4(fGradVal, fGradVal, fGradVal, 1.0f);
}

//--------------------------------------------------------------------------------------
// This shader creates a procedural texture for the radar colors, for use as 
// a legend for the radar colors lights-per-tile visualization.
//--------------------------------------------------------------------------------------
float4 DebugDrawLegendForNumLightsPerTileRadarColorsPS( VS_OUTPUT_POS_TEX Input ) : SV_TARGET
{
    uint nBandIdx = floor(16.999f*Input.TextureUV.y);

    // black for no lights
    if( nBandIdx == 0 ) return float4(0,0,0,1);
    // light purple for reaching the max
    else if( nBandIdx == 15 ) return float4(0.847,0.745,0.921,1);
    // white for going over the max
    else if ( nBandIdx == 16 ) return float4(1,1,1,1);
    // else use weather radar colors
    else
    {
        // nBandIdx should be in the range [1,14]
        uint nColorIndex = nBandIdx-1;
        return kRadarColors[nColorIndex];
    }
}

