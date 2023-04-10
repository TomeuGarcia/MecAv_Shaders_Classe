Shader "Unlit/Shader_01_FXStack_ToonWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
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

        _WaterColor("Water Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _FrothColor("Water Color", Color) = (0.0, 0.0, 0.3, 1.0)
        _WaterDepth("Water Depth", Range(0, 1)) = 0.3
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
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4  _DirWave1, _DirWave2;
            float _FreqWave1, _FreqWave2;
            float _WavLengthWave1, _WavLengthWave2;
            float _TimeOffsetWave1, _TimeOffsetWave2;
            float _HeightWave1, _HeightWave2;
            float _PanningSpeed;

            fixed4 _WaterColor, _FrothColor;
            half _WaterDepth;


            half getWave(half3 direction, float3 worldPosition, float time, float frequency, float waveLength)
            {   
                float waveOffset = (direction.x * worldPosition.x) + (direction.y * worldPosition.y) + (direction.z * worldPosition.z);
                return (sin((time * frequency) + (waveOffset * waveLength)) + 1.0) * 0.5;
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
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {               
                // sample the texture
                float2 uv = i.uv;
                uv += normalize(_DirWave1.xz) * (_Time.y * _FreqWave1 * _PanningSpeed);
                uv += normalize(_DirWave2.xz) * (_Time.y * _FreqWave2 * _PanningSpeed);

                fixed4 textureColor = tex2D(_MainTex, uv);
                textureColor = lerp(_WaterColor, _FrothColor, textureColor.x);
                //textureColor = lerp(_WaterColor, _FrothColor, floor(textureColor.x + 0.3));

                textureColor *= lerp(_WaterDepth, 1.0, i.waveT);

                return textureColor;
            }

            ENDCG
        }
    }
}
