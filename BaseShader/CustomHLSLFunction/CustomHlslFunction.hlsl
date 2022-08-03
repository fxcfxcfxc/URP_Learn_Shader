

//====================================================UE4节点函数 搬运================================
 

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


