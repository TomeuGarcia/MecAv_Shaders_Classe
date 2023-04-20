Shader "01_FXStack/Shader_01_FXStack_ToonWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FoamTex ("Foam Texture", 2D) = "white" {}
        
        _DirWave1 ("Direction Wave 1", Vector) = (0, 0, 1, 0)
        _FreqWave1 ("Frequency Wave 1", Range(0, 10)) = 1
        _WavLengthWave1 ("Wave Length Wave 1", Range(0, 10)) = 1
        _TimeOffsetWave1 ("Time Offset Wave 1", Range(0, 3)) = 0
        _HeightWave1 ("Height Wave 1", Range(0, 3)) = 0.5

        _DirWave2 ("Direction Wave 2", Vector) = (1, 0, 0, 0)
        _FreqWave2 ("Frequency Wave 2", Range(0, 10)) = 1
        _WavLengthWave2 ("Wave Length Wave 2", Range(0, 10)) = 1
        _TimeOffsetWave2 ("Time Offset Wave 2", Range(0, 3)) = 0
        _HeightWave2 ("Height Wave 2", Range(0, 3)) = 0.5

        _PanningSpeed("Panning Speed", Range(0, 1)) = 0.1

        _WaterShallowColor("Water Shallow Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _WaterDeepColor("Water Deep Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _WaterHorizonColor("Water Horizon Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _FoamColor("Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _WaterDepth("Water Depth", Range(0, 1)) = 0.3

        _DepthDistance("Depth Distance", Range(0, 10)) = 1
        _DepthMethod("Depth Method", Range(0, 1)) = 1
        _FoamDistance("Foam Distance", Range(0, 10)) = 1
        _FoamSpread("Foam Spread", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "../../MyShaderLibraries/MyFunctions.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;     

                half waveT : TEXCOORD1;        
                float3 worldPosition : TEXCOORD2;        
                float4 screenPosition : TEXCOORD3;    
                half3 worldNormal : TEXCOORD4;    
            };


            sampler2D _MainTex, _FoamTex;
            float4 _MainTex_ST;

            half4  _DirWave1, _DirWave2;
            float _FreqWave1, _FreqWave2;
            float _WavLengthWave1, _WavLengthWave2;
            float _TimeOffsetWave1, _TimeOffsetWave2;
            float _HeightWave1, _HeightWave2;
            float _PanningSpeed;

            fixed4 _WaterShallowColor, _WaterDeepColor, _WaterHorizonColor, _FoamColor;
            half _WaterDepth;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);            
            float _DepthDistance, _DepthSharpness, _FoamDistance, _FoamSpread;
            float _DepthMethod;



            half getWave(half3 direction, float3 worldPosition, float time, float frequency, float waveLength)
            {   
                float waveOffset = (direction.x * worldPosition.x) + (direction.y * worldPosition.y) + (direction.z * worldPosition.z);
                return (sin((time * frequency) + (waveOffset * waveLength)) + 1.0) * 0.5;
            }            
            

            float depthFade(float4 screenPosition, float distance)
            {
                float sceneLinearDepth01 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(screenPosition)));
                float depthDifference = sceneLinearDepth01 - screenPosition.z;
                depthDifference /= distance;
                depthDifference = saturate(depthDifference);
                return depthDifference;
            }

            float depthHeightFade(float3 worldPosition, float4 screenPosition, float3 cameraWorldPosition, float depthDistance, float power)
            {
                float3 toCameraVector = worldPosition - cameraWorldPosition;
                toCameraVector /= screenPosition.w;
                float sceneLinearDepth01 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(screenPosition)));
                toCameraVector *= sceneLinearDepth01;

                float3 worldSpaceScenePosition = toCameraVector + cameraWorldPosition;
                
                float3 worldOffset = worldPosition - worldSpaceScenePosition;
                float depthFade = saturate(pow(-worldOffset.y / depthDistance, power));
                return depthFade;   
            }


            v2f vert (appdata v)
            {
                v2f o;               

                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
                half3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

                half wave1 = getWave(normalize(_DirWave1.xyz), worldPosition, _Time.y + _TimeOffsetWave1, _FreqWave1, _WavLengthWave1);
                half wave2 = getWave(normalize(_DirWave2.xyz), worldPosition, _Time.y + _TimeOffsetWave2, _FreqWave2, _WavLengthWave2);                

                o.waveT = (wave1 + wave2) / 2.0;

                wave1 *= _HeightWave1;
                wave2 *= _HeightWave2;
                    
                worldPosition += worldNormal * (wave1 + wave2);


                o.vertex = UnityWorldToClipPos(float4(worldPosition, 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPosition = worldPosition;
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.worldNormal = worldNormal;
                COMPUTE_EYEDEPTH(o.screenPosition.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {               
                // sample the texture
                float2 uv = i.uv;
                uv += normalize(_DirWave1.xz) * (_Time.y * _FreqWave1 * _PanningSpeed);
                uv += normalize(_DirWave2.xz) * (_Time.y * _FreqWave2 * _PanningSpeed);

                fixed4 textureColor = tex2D(_MainTex, uv);
                //textureColor = lerp(_WaterColor, _FrothColor, textureColor.x);
                //textureColor = lerp(_WaterColor, _FrothColor, floor(textureColor.x + 0.3));

                //textureColor *= lerp(_WaterDepth, 1.0, i.waveT);


                float depthF = depthFade(i.screenPosition, _DepthDistance);
                float depthHeightF = depthHeightFade(i.worldPosition, i.screenPosition, _WorldSpaceCameraPos, _DepthDistance, 2);

                float depth = lerp(depthF, depthHeightF, _DepthMethod);
                
                
                //return fixed4(depth, depth, depth, 1);
                fixed4 outColor = lerp(_WaterShallowColor, _WaterDeepColor, depth);

                half3 directionToCamera = normalize(_WorldSpaceCameraPos - i.worldPosition); 
                float horizonT = fresnel(directionToCamera, i.worldNormal, 2.0);
                outColor = lerp(outColor, _WaterHorizonColor, horizonT);

                float foamT = depthHeightFade(i.worldPosition, i.screenPosition, _WorldSpaceCameraPos, _FoamDistance, 2);
                float foamMask = step(foamT, _FoamSpread);

                float foamTexture = tex2D(_FoamTex, uv * 5).x;

                return saturate((1-foamT) - foamTexture);

                outColor = lerp(outColor, _FoamColor, foamMask);

                return outColor;

                return textureColor;

            }

            ENDCG
        }
    }
}
