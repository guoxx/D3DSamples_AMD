//
// Copyright 2014 ADVANCED MICRO DEVICES, INC.  All Rights Reserved.
//
// AMD is granting you permission to use this software and documentation (if
// any) (collectively, the "Materials") pursuant to the terms and conditions
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
// File: LightUtil.h
//
// Helper functions for the TiledLighting11 sample.
//--------------------------------------------------------------------------------------

#pragma once

#include "..\\DXUT\\Core\\DXUT.h"
#include "CommonConstants.h"

// Forward declarations
namespace AMD
{
    class ShaderCache;
}
namespace TiledLighting11
{
    class CommonUtil;
}

namespace TiledLighting11
{
    enum LightingMode
    {
        LIGHTING_SHADOWS = 0,
        LIGHTING_RANDOM,
        LIGHTING_NUM_MODES
    };

    class LightUtil
    {
    public:
        // Constructor / destructor
        LightUtil();
        ~LightUtil();

        static void InitLights( const DirectX::XMVECTOR &BBoxMin, const DirectX::XMVECTOR &BBoxMax );

        // returning a 2D array as XMMATRIX*[6], please forgive this ugly syntax
        static const DirectX::XMMATRIX (*GetShadowCastingPointLightViewProjTransposedArray())[6];
        static const DirectX::XMMATRIX (*GetShadowCastingPointLightViewProjInvTransposedArray())[6];

        static const DirectX::XMMATRIX* GetShadowCastingSpotLightViewProjTransposedArray();
        static const DirectX::XMMATRIX* GetShadowCastingSpotLightViewProjInvTransposedArray();

        void AddShadersToCache( AMD::ShaderCache *pShaderCache );

        void RenderLights( float fElapsedTime, unsigned uNumPointLights, unsigned uNumSpotLights, int nLightingMode, const CommonUtil& CommonUtil ) const;

        // Various hook functions
        HRESULT OnCreateDevice( ID3D11Device* pd3dDevice );
        void OnDestroyDevice();
        HRESULT OnResizedSwapChain( ID3D11Device* pd3dDevice, const DXGI_SURFACE_DESC* pBackBufferSurfaceDesc );
        void OnReleasingSwapChain();

        ID3D11ShaderResourceView * const * GetPointLightBufferCenterAndRadiusSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingPointLightBufferCenterAndRadiusSRV : &m_pPointLightBufferCenterAndRadiusSRV; }
        ID3D11ShaderResourceView * const * GetPointLightBufferColorSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingPointLightBufferColorSRV : &m_pPointLightBufferColorSRV; }

        ID3D11ShaderResourceView * const * GetSpotLightBufferCenterAndRadiusSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingSpotLightBufferCenterAndRadiusSRV : &m_pSpotLightBufferCenterAndRadiusSRV; }
        ID3D11ShaderResourceView * const * GetSpotLightBufferColorSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingSpotLightBufferColorSRV : &m_pSpotLightBufferColorSRV; }
        ID3D11ShaderResourceView * const * GetSpotLightBufferSpotParamsSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingSpotLightBufferSpotParamsSRV : &m_pSpotLightBufferSpotParamsSRV; }
        ID3D11ShaderResourceView * const * GetSpotLightBufferSpotMatricesSRVParam( int nLightingMode ) const { return (nLightingMode == LIGHTING_SHADOWS) ? &m_pShadowCastingSpotLightBufferSpotMatricesSRV : &m_pSpotLightBufferSpotMatricesSRV; }

    private:

        // point lights
        ID3D11Buffer*               m_pPointLightBufferCenterAndRadius;
        ID3D11ShaderResourceView*   m_pPointLightBufferCenterAndRadiusSRV;
        ID3D11Buffer*               m_pPointLightBufferColor;
        ID3D11ShaderResourceView*   m_pPointLightBufferColorSRV;

        // shadow casting point lights
        ID3D11Buffer*               m_pShadowCastingPointLightBufferCenterAndRadius;
        ID3D11ShaderResourceView*   m_pShadowCastingPointLightBufferCenterAndRadiusSRV;
        ID3D11Buffer*               m_pShadowCastingPointLightBufferColor;
        ID3D11ShaderResourceView*   m_pShadowCastingPointLightBufferColorSRV;

        // spot lights
        ID3D11Buffer*               m_pSpotLightBufferCenterAndRadius;
        ID3D11ShaderResourceView*   m_pSpotLightBufferCenterAndRadiusSRV;
        ID3D11Buffer*               m_pSpotLightBufferColor;
        ID3D11ShaderResourceView*   m_pSpotLightBufferColorSRV;
        ID3D11Buffer*               m_pSpotLightBufferSpotParams;
        ID3D11ShaderResourceView*   m_pSpotLightBufferSpotParamsSRV;

        // these are only used for debug drawing the spot lights
        ID3D11Buffer*               m_pSpotLightBufferSpotMatrices;
        ID3D11ShaderResourceView*   m_pSpotLightBufferSpotMatricesSRV;

        // spot lights
        ID3D11Buffer*               m_pShadowCastingSpotLightBufferCenterAndRadius;
        ID3D11ShaderResourceView*   m_pShadowCastingSpotLightBufferCenterAndRadiusSRV;
        ID3D11Buffer*               m_pShadowCastingSpotLightBufferColor;
        ID3D11ShaderResourceView*   m_pShadowCastingSpotLightBufferColorSRV;
        ID3D11Buffer*               m_pShadowCastingSpotLightBufferSpotParams;
        ID3D11ShaderResourceView*   m_pShadowCastingSpotLightBufferSpotParamsSRV;

        // these are only used for debug drawing the spot lights
        ID3D11Buffer*               m_pShadowCastingSpotLightBufferSpotMatrices;
        ID3D11ShaderResourceView*   m_pShadowCastingSpotLightBufferSpotMatricesSRV;

        // sprite quad VB (for debug drawing the point lights)
        ID3D11Buffer*               m_pQuadForLightsVB;

        // cone VB and IB (for debug drawing the spot lights)
        ID3D11Buffer*               m_pConeForSpotLightsVB;
        ID3D11Buffer*               m_pConeForSpotLightsIB;

        // debug draw shaders for the point lights
        ID3D11VertexShader*         m_pDebugDrawPointLightsVS;
        ID3D11PixelShader*          m_pDebugDrawPointLightsPS;
        ID3D11InputLayout*          m_pDebugDrawPointLightsLayout11;

        // debug draw shaders for the spot lights
        ID3D11VertexShader*         m_pDebugDrawSpotLightsVS;
        ID3D11PixelShader*          m_pDebugDrawSpotLightsPS;
        ID3D11InputLayout*          m_pDebugDrawSpotLightsLayout11;

        // state
        ID3D11BlendState*           m_pBlendStateAdditive;
    };

} // namespace TiledLighting11

//--------------------------------------------------------------------------------------
// EOF
//--------------------------------------------------------------------------------------
