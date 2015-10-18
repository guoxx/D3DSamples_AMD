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
// File: RSMRenderer.h
//
// Reflective Shadow Map rendering class
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
    struct GuiState;
    struct Scene;
    class CommonUtil;
    class LightUtil;
}

namespace TiledLighting11
{
    typedef void (*UpdateCameraCallback)( const DirectX::XMMATRIX& mViewProj );

    class RSMRenderer
    {
    public:

        RSMRenderer();
        ~RSMRenderer();

        void SetCallbacks( UpdateCameraCallback cameraCallback );

        void AddShadersToCache( AMD::ShaderCache *pShaderCache );

        // Various hook functions
        void OnCreateDevice( ID3D11Device* pd3dDevice );
        void OnDestroyDevice();
        HRESULT OnResizedSwapChain( ID3D11Device* pd3dDevice, const DXGI_SURFACE_DESC* pBackBufferSurfaceDesc );
        void OnReleasingSwapChain();

        void RenderSpotRSMs( int NumSpotLights, const GuiState& CurrentGuiState, const Scene& Scene, const CommonUtil& CommonUtil );
        void RenderPointRSMs( int NumPointLights, const GuiState& CurrentGuiState, const Scene& Scene, const CommonUtil& CommonUtil );
        void GenerateVPLs( int NumSpotLights, int NumPointLights, const LightUtil& LightUtil );

        ID3D11ShaderResourceView* GetSpotDepthSRV() { return m_SpotAtlas.m_pDepthSRV; }
        ID3D11ShaderResourceView* GetSpotNormalSRV() { return m_SpotAtlas.m_pNormalSRV; }
        ID3D11ShaderResourceView* GetSpotDiffuseSRV() { return m_SpotAtlas.m_pDiffuseSRV; }

        ID3D11ShaderResourceView* GetPointDepthSRV() { return m_PointAtlas.m_pDepthSRV; }
        ID3D11ShaderResourceView* GetPointNormalSRV() { return m_PointAtlas.m_pNormalSRV; }
        ID3D11ShaderResourceView* GetPointDiffuseSRV() { return m_PointAtlas.m_pDiffuseSRV; }

        ID3D11ShaderResourceView * const * GetVPLBufferCenterAndRadiusSRVParam() const { return &m_pVPLBufferCenterAndRadiusSRV; }
        ID3D11ShaderResourceView * const * GetVPLBufferDataSRVParam() const { return &m_pVPLBufferDataSRV; }

        int ReadbackNumVPLs();

    private:
        void RenderRSMScene( const GuiState& CurrentGuiState, const Scene& Scene, const CommonUtil& CommonUtil );

    private:

        UpdateCameraCallback        m_CameraCallback;

        struct GBufferAtlas
        {
            void Release()
            {
                SAFE_RELEASE( m_pDepthSRV );
                SAFE_RELEASE( m_pDepthDSV );
                SAFE_RELEASE( m_pDepthTexture );

                SAFE_RELEASE( m_pNormalRTV );
                SAFE_RELEASE( m_pNormalSRV );
                SAFE_RELEASE( m_pNormalTexture );

                SAFE_RELEASE( m_pDiffuseRTV );
                SAFE_RELEASE( m_pDiffuseSRV );
                SAFE_RELEASE( m_pDiffuseTexture );
            }

            ID3D11Texture2D*            m_pDepthTexture;
            ID3D11DepthStencilView*     m_pDepthDSV;
            ID3D11ShaderResourceView*   m_pDepthSRV;

            ID3D11Texture2D*            m_pNormalTexture;
            ID3D11RenderTargetView*     m_pNormalRTV;
            ID3D11ShaderResourceView*   m_pNormalSRV;

            ID3D11Texture2D*            m_pDiffuseTexture;
            ID3D11RenderTargetView*     m_pDiffuseRTV;
            ID3D11ShaderResourceView*   m_pDiffuseSRV;
        };

        GBufferAtlas                m_SpotAtlas;
        GBufferAtlas                m_PointAtlas;

        ID3D11Buffer*               m_pVPLBufferCenterAndRadius;
        ID3D11ShaderResourceView*   m_pVPLBufferCenterAndRadiusSRV;
        ID3D11UnorderedAccessView*  m_pVPLBufferCenterAndRadiusUAV;

        ID3D11Buffer*               m_pVPLBufferData;
        ID3D11ShaderResourceView*   m_pVPLBufferDataSRV;
        ID3D11UnorderedAccessView*  m_pVPLBufferDataUAV;

        ID3D11Buffer*               m_pSpotInvViewProjBuffer;
        ID3D11ShaderResourceView*   m_pSpotInvViewProjBufferSRV;

        ID3D11Buffer*               m_pPointInvViewProjBuffer;
        ID3D11ShaderResourceView*   m_pPointInvViewProjBufferSRV;

        ID3D11Buffer*               m_pNumVPLsConstantBuffer;
        ID3D11Buffer*               m_pCPUReadbackConstantBuffer;

        ID3D11VertexShader*         m_pRSMVS;
        ID3D11PixelShader*          m_pRSMPS;
        ID3D11InputLayout*          m_pRSMLayout;

        ID3D11ComputeShader*        m_pGenerateSpotVPLsCS;
        ID3D11ComputeShader*        m_pGeneratePointVPLsCS;
    };
    
} // namespace TiledLighting11

//--------------------------------------------------------------------------------------
// EOF
//--------------------------------------------------------------------------------------
