
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
//====================================================UE4节点函数 搬运================================
 
#define pi 3.1415926

// UV动画 和缩放
float2 PannerUV(float2 srcUV, float scaleUV, float speedX,float speedY)
{
     float2 outUV =  srcUV * scaleUV;
     outUV = outUV + float2(speedX * _Time.x, speedY * _Time.x);
     return outUV;
}



// GetDepthEdge 获取类似水面效果，返回边缘黑色
//ScreenUV(屏幕UV)，depthScale(浮点精度控制)
float GetDepthEdge(float2 ScreenUV, float depthScale, float w)
{
  float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,ScreenUV).r;
  depth = LinearEyeDepth(depth,_ZBufferParams);
  float edgeline = saturate( (depth - w) / depthScale ) ;
  return edgeline;
}



// CustomRotator  UV旋转
float2 CustomRotator(float2 uv, float2 rotationCenter, float  angle)
{
    float dre = angle * (pi/180) ; 
    float cosA = cos(dre);
    float sinA = sin(dre);
    float2x2 rotMartix = float2x2(cosA,-sinA,
                                  sinA, cosA);

    uv =  uv - rotationCenter;
    uv = mul(rotMartix,uv);
    uv = uv + rotationCenter;
    return uv;
}


//RotateAboutAxis 旋转物体
/** Rotates Position about the given axis by the given angle, in radians, and returns the offset to Position. */
float3 RotateAboutAxis(float3 normalizedRotationAxis,float rotationAngle, float3 pivotPointWS, float3 vertexposWS )
{
    // Project Position onto the rotation axis and find the closest point on the axis to Position
    float3 ClosestPointOnAxis =  pivotPointWS  + normalizedRotationAxis * dot(normalizedRotationAxis, vertexposWS - pivotPointWS);
    // Construct orthogonal axes in the plane of the rotation
    float3 UAxis =  vertexposWS - ClosestPointOnAxis;
    float3 VAxis =  cross(normalizedRotationAxis, UAxis);
    float CosAngle;
    float SinAngle;
    sincos(rotationAngle,CosAngle,SinAngle);
    
    // Rotate using the orthogonal axes
    float3 R = UAxis  * CosAngle + VAxis * SinAngle;
    // Reconstruct the rotated world space position
    float3 RotatedPosition = ClosestPointOnAxis  +R;
    // Convert from position to a position offset
    return RotatedPosition - vertexposWS;
}


