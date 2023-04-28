Shader "01_FXStack/Shader_01_FXStack_ToonWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FoamTex ("Foam Texture", 2D) = "white" {}
        _DepthRampTex ("Depth Ramp Texture", 2D) = "white" {}
        
        // Wave 1
        _DirWave1 ("Direction Wave 1", Vector) = (0, 0, 1, 0)
        _FreqWave1 ("Frequency Wave 1", Range(0, 10)) = 1
        _WavLengthWave1 ("Wave Length Wave 1", Range(0, 10)) = 1
        _TimeOffsetWave1 ("Time Offset Wave 1", Range(0, 3)) = 0
        _HeightWave1 ("Height Wave 1", Range(0, 3)) = 0.5

        // Wave 2
        _DirWave2 ("Direction Wave 2", Vector) = (1, 0, 0, 0)
        _FreqWave2 ("Frequency Wave 2", Range(0, 10)) = 1
        _WavLengthWave2 ("Wave Length Wave 2", Range(0, 10)) = 1
        _TimeOffsetWave2 ("Time Offset Wave 2", Range(0, 3)) = 0
        _HeightWave2 ("Height Wave 2", Range(0, 3)) = 0.5

        // Water
        _WaterShallowColor("Water Shallow Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _WaterDeepColor("Water Deep Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _WaterHorizonColor("Water Horizon Color", Color) = (0.0, 0.0, 1.0, 1.0)        
        _DepthDistance("Depth Distance", Range(0, 10)) = 1
        _DepthMethod("Depth: Zbuf vs Ydiff", Range(0, 1)) = 1

        // Foam
        _FoamColor("Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _FoamPanningSpeed("Foam Panning Speed", Range(0, 1)) = 0.1
        _FoamDistance("Foam Distance", Range(0, 10)) = 1
        _FoamSpread("Foam Spread", Range(0, 1)) = 0.1

        // Specular
        _SpecularStrength("Specular Strength", Float) = 1.0
        _SpecularPow("Specular Pow", Float) = 2.0

        // Normals recomputation
        _NormalTexelSize("Normal Texel Size", Range(0.001, 1)) = 0.001
        _NormalTexelDist("Normal Texel Dist", Range(0, 500)) = 100

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
            #include "Lighting.cginc"
            #include "../../MyShaderLibraries/MyFunctions.cginc"
            #include "../../MyShaderLibraries/MyLighting.cginc"

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
                float3 wavelessWorldPosition : TEXCOORD5;        
            };


            sampler2D _MainTex, _FoamTex, _DepthRampTex;
            float4 _MainTex_ST;

            half4  _DirWave1, _DirWave2;
            float _FreqWave1, _FreqWave2;
            float _WavLengthWave1, _WavLengthWave2;
            float _TimeOffsetWave1, _TimeOffsetWave2;
            float _HeightWave1, _HeightWave2;
            float _FoamPanningSpeed;

            fixed4 _WaterShallowColor, _WaterDeepColor, _WaterHorizonColor, _FoamColor;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);            
            float _DepthDistance, _DepthSharpness, _FoamDistance, _FoamSpread;
            float _DepthMethod;

            float _SpecularStrength, _SpecularPow;

            float _NormalTexelSize, _NormalTexelDist;


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

            half3 filterNormal(half3 direction, float3 worldPosition, float time, float frequency, float waveLength, float texelSize, fixed texelDist, fixed maxHeight)
            {
                float4 h;
                h.x = getWave(direction, worldPosition + float3(0, 0, -texelSize * texelDist), time, frequency, waveLength) * maxHeight;
                h.y = getWave(direction, worldPosition + float3(-texelSize * texelDist, 0, 0), time, frequency, waveLength) * maxHeight;
                h.z = getWave(direction, worldPosition + float3(texelSize * texelDist, 0, 0), time, frequency, waveLength) * maxHeight;
                h.w = getWave(direction, worldPosition + float3(0, 0, texelSize * texelDist), time, frequency, waveLength) * maxHeight;

                float3 n;
                
                n.z = h.w - h.x;
                n.x = h.z - h.y;
                n.y = 2;
                return normalize(n);
                                
                n.z = 2;
                n.x = h.z - h.y;
                n.y = h.w - h.x;                              
                //return normalize(n);

                n.z = 2;
                n.x = h.y - h.z;
                n.y = h.w - h.x;                              
                return normalize(n);
            }


            v2f vert (appdata v)
            {
                v2f o;               

                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
                half3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

                half3 dirWave1 = normalize(_DirWave1.xyz);
                half wave1 = getWave(dirWave1, worldPosition, _Time.y + _TimeOffsetWave1, _FreqWave1, _WavLengthWave1);
                half3 wave1Normal = filterNormal(dirWave1, worldPosition, _Time.y + _TimeOffsetWave1, _FreqWave1, _WavLengthWave1, 
                                                _NormalTexelSize, _NormalTexelDist, _HeightWave1);

                half3 dirWave2 = normalize(_DirWave2.xyz);
                half wave2 = getWave(normalize(_DirWave2.xyz), worldPosition, _Time.y + _TimeOffsetWave2, _FreqWave2, _WavLengthWave2); 
                half3 wave2Normal = filterNormal(dirWave2, worldPosition, _Time.y + _TimeOffsetWave2, _FreqWave2, _WavLengthWave2, 
                                                _NormalTexelSize, _NormalTexelDist, _HeightWave2);               

                o.waveT = (wave1 + wave2) / 2.0;

                wave1 *= _HeightWave1;
                wave2 *= _HeightWave2;
                    
                o.wavelessWorldPosition = worldPosition;
                worldPosition += worldNormal * (wave1 + wave2);


                o.vertex = UnityWorldToClipPos(float4(worldPosition, 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPosition = worldPosition;
                o.screenPosition = ComputeScreenPos(o.vertex);
                //o.worldNormal = worldNormal;
                //half3 noiseNormal = tex2Dlod(heightMap, uv + float4(texelSize * float2(0, -1 * texelDist), 0, 0)).x * maxHeight;
                o.worldNormal = normalize(wave1Normal + wave2Normal);

                COMPUTE_EYEDEPTH(o.screenPosition.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {               
                // sample the texture
                float2 uv = i.uv;
                uv += normalize(_DirWave1.xz) * (_Time.y * _FreqWave1 * _FoamPanningSpeed);
                uv += normalize(_DirWave2.xz) * (_Time.y * _FreqWave2 * _FoamPanningSpeed);

                fixed4 textureColor = tex2D(_MainTex, uv);
                //textureColor = lerp(_WaterColor, _FrothColor, textureColor.x);
                //textureColor = lerp(_WaterColor, _FrothColor, floor(textureColor.x + 0.3));



                float depthF = depthFade(i.screenPosition, _DepthDistance);
                float depthHeightF = depthHeightFade(i.worldPosition, i.screenPosition, _WorldSpaceCameraPos, _DepthDistance, 2);

                float depth = lerp(depthF, depthHeightF, _DepthMethod);
                
                
                //return fixed4(depth, depth, depth, 1);
                float2 depthRampUV = min(depth, 0.9);
                half depthRampT = tex2D(_DepthRampTex, depthRampUV);                
                //depthRampT = depth;
                fixed4 outColor = lerp(_WaterShallowColor, _WaterDeepColor, depthRampT);
                outColor *= lerp(0.3, 1.0, i.waveT);

                half3 directionToCamera = normalize(_WorldSpaceCameraPos - i.worldPosition); 
                float horizonT = fresnel(directionToCamera, i.worldNormal, 2.0);
                outColor = lerp(outColor, _WaterHorizonColor, horizonT);


                float foamT = depthHeightFade(i.wavelessWorldPosition, i.screenPosition, _WorldSpaceCameraPos, _FoamDistance, 2);
                float foamMask = step(foamT, _FoamSpread);

                float foamTexture = tex2D(_FoamTex, uv * 5).x;

                foamMask = step(foamT, foamTexture);

                //return saturate((1-foamT) - foamTexture);

                outColor = lerp(outColor, _FoamColor, foamMask);

                // Specular
                half3 lightDirection = _WorldSpaceLightPos0.xyz;
                fixed4 lightColor = fixed4(1,1,1,1);
                outColor += computeSpecular(directionToCamera, i.worldNormal, lightDirection, lightColor, _SpecularStrength, _SpecularPow);

                return outColor;

            }

            ENDCG
        }
    }
}
