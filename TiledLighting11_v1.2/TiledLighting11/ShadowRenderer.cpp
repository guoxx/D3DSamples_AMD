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
// File: ShadowRenderer.cpp
//
// Shadow rendering class
//--------------------------------------------------------------------------------------

#include "..\\DXUT\\Core\\DXUT.h"

#include "..\\AMD_SDK\\AMD_SDK.h"

#include "ShadowRenderer.h"
#include "LightUtil.h"


#pragma warning( disable : 4100 ) // disable unreference formal parameter warnings for /W4 builds

using namespace DirectX;

static const int gPointShadowResolution = 256;
static const int gSpotShadowResolution = 256;


namespace TiledLighting11
{

    ShadowRenderer::ShadowRenderer()
        :m_CameraCallback( 0 ),
        m_RenderCallback( 0 ),
        m_pPointAtlasTexture( 0 ),
        m_pPointAtlasView( 0 ),
        m_pPointAtlasSRV( 0 ),
        m_pSpotAtlasTexture( 0 ),
        m_pSpotAtlasView( 0 ),
        m_pSpotAtlasSRV( 0 )
    {
    }


    ShadowRenderer::~ShadowRenderer()
    {
    }


    void ShadowRenderer::SetCallbacks( UpdateCameraCallback cameraCallback, RenderSceneCallback renderCallback )
    {
        m_CameraCallback = cameraCallback;
        m_RenderCallback = renderCallback;
    }


    HRESULT ShadowRenderer::OnCreateDevice( ID3D11Device* pd3dDevice )
    {
        HRESULT hr;
        V_RETURN( AMD::CreateDepthStencilSurface( &m_pPointAtlasTexture, &m_pPointAtlasSRV, &m_pPointAtlasView, DXGI_FORMAT_D16_UNORM, DXGI_FORMAT_R16_UNORM, 6 * gPointShadowResolution, MAX_NUM_SHADOWCASTING_POINTS * gPointShadowResolution, 1 ) );
        V_RETURN( AMD::CreateDepthStencilSurface( &m_pSpotAtlasTexture, &m_pSpotAtlasSRV, &m_pSpotAtlasView, DXGI_FORMAT_D16_UNORM, DXGI_FORMAT_R16_UNORM, MAX_NUM_SHADOWCASTING_SPOTS * gSpotShadowResolution, gSpotShadowResolution, 1 ) );
        return S_OK;
    }


    void ShadowRenderer::OnDestroyDevice()
    {
        SAFE_RELEASE( m_pSpotAtlasSRV );
        SAFE_RELEASE( m_pSpotAtlasView );
        SAFE_RELEASE( m_pSpotAtlasTexture );

        SAFE_RELEASE( m_pPointAtlasSRV );
        SAFE_RELEASE( m_pPointAtlasView );
        SAFE_RELEASE( m_pPointAtlasTexture );
    }

    HRESULT ShadowRenderer::OnResizedSwapChain( ID3D11Device* pd3dDevice, const DXGI_SURFACE_DESC* pBackBufferSurfaceDesc )
    {
        return S_OK;
    }

    void ShadowRenderer::OnReleasingSwapChain()
    {
    }

    void ShadowRenderer::RenderPointMap( int numShadowCastingPointLights )
    {
        AMDProfileEvent( AMD_PROFILE_RED, L"PointShadows" ); 

        ID3D11DeviceContext* pd3dImmediateContext = DXUTGetD3D11DeviceContext();

        D3D11_VIEWPORT oldVp[ 8 ];
        UINT numVPs = 1;
        pd3dImmediateContext->RSGetViewports( &numVPs, oldVp );

        D3D11_VIEWPORT vp;
        vp.Width = gPointShadowResolution;
        vp.Height = gPointShadowResolution;
        vp.MinDepth = 0.0f;
        vp.MaxDepth = 1.0f;

        pd3dImmediateContext->ClearDepthStencilView( m_pPointAtlasView, D3D11_CLEAR_DEPTH, 1.0f, 0 );

        ID3D11RenderTargetView* pNULLRTV = NULL;
        pd3dImmediateContext->OMSetRenderTargets( 1, &pNULLRTV, m_pPointAtlasView );

        const XMMATRIX (*PointLightViewProjArray)[6] = LightUtil::GetShadowCastingPointLightViewProjTransposedArray();

        for ( int p = 0; p < numShadowCastingPointLights; p++ )
        {
            vp.TopLeftY = (float)p * gPointShadowResolution;

            for ( int i = 0; i < 6; i++ )
            {
                m_CameraCallback( PointLightViewProjArray[p][i] );

                vp.TopLeftX = (float)i * gPointShadowResolution;
                pd3dImmediateContext->RSSetViewports( 1, &vp );

                m_RenderCallback();
            }
        }

        pd3dImmediateContext->RSSetViewports( 1, oldVp );
    }


    void ShadowRenderer::RenderSpotMap( int numShadowCastingSpotLights )
    {
        AMDProfileEvent( AMD_PROFILE_RED, L"SpotShadows" ); 

        ID3D11DeviceContext* pd3dImmediateContext = DXUTGetD3D11DeviceContext();

        D3D11_VIEWPORT oldVp[ 8 ];
        UINT numVPs = 1;
        pd3dImmediateContext->RSGetViewports( &numVPs, oldVp );

        D3D11_VIEWPORT vp;
        vp.Width = gSpotShadowResolution;
        vp.Height = gSpotShadowResolution;
        vp.MinDepth = 0.0f;
        vp.MaxDepth = 1.0f;
        vp.TopLeftY = 0.0f;

        pd3dImmediateContext->ClearDepthStencilView( m_pSpotAtlasView, D3D11_CLEAR_DEPTH, 1.0f, 0 );

        ID3D11RenderTargetView* pNULLRTV = NULL;
        pd3dImmediateContext->OMSetRenderTargets( 1, &pNULLRTV, m_pSpotAtlasView );

        const XMMATRIX* SpotLightViewProjArray = LightUtil::GetShadowCastingSpotLightViewProjTransposedArray();

        for ( int i = 0; i < numShadowCastingSpotLights; i++ )
        {
            vp.TopLeftX = (float)i * gSpotShadowResolution;

            m_CameraCallback( SpotLightViewProjArray[i] );

            pd3dImmediateContext->RSSetViewports( 1, &vp );

            m_RenderCallback();
        }

        pd3dImmediateContext->RSSetViewports( 1, oldVp );
    }

} // namespace TiledLighting11

//--------------------------------------------------------------------------------------
// EOF
//--------------------------------------------------------------------------------------
