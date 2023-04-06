Shader "01_FXStack/Shader_01_FXStack_Celshade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _LightStepsInverse("Light Steps Inverse", Range(0.0, 1.0)) = 0.3
        _LightStepsStrength("Light Steps Strength", Range(0.0, 1.0)) = 0.3
        _Brightness("Brightness", Range(0.0, 1.0)) = 0.3

        _RimThinness("Rim Light Thinness", Range(0.0, 1.0)) = 0.1
        _RimThreshold("Rim Light Threshold", Range(0.0, 4.0)) = 0.1

        _OutlineWidth("Outline Width", Range(0.0, 2.0)) = 0.2
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _NormalVSOriginDisplacement("Normal VS Origin displacement", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "PassFlags"="OnlyDirectional" }
        LOD 100

        // Outline Pass
        Pass
        {
            Tags { "RenderType"="Opaque" }
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            half _OutlineWidth;
            half4 _OutlineColor;
            half _NormalVSOriginDisplacement;


            v2f vert (appdata v)
            {
                v2f o;

                half3 directionFromOrigin = normalize(v.vertex.xyz);
                half3 displacementDirection = lerp(v.normal, directionFromOrigin, _NormalVSOriginDisplacement);
                float3 displacedPosition = v.vertex.xyz + (displacementDirection  * _OutlineWidth);

                float4 vertexPosition = float4(displacedPosition, 1.0);

                o.vertex = UnityObjectToClipPos(vertexPosition);

                

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }


        // Celshade Pass
        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

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

                float3 worldPosition : TEXCOORD1;
                half3 worldNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _AmbientColor;
            float _LightStepsInverse;
            float _LightStepsStrength;
            float _Brightness;

            float _RimThinness, _RimThreshold;


            float SteppedLight(half3 worldNormal, half3 lightDirection)
            {
                float lightIntensity = saturate(dot(worldNormal, lightDirection));
                return floor(lightIntensity / _LightStepsInverse);
            }

            float fresnel(half3 dirToCam, half3 worldSpaceVertexNormal, half exponent)
            {
                float value = saturate(dot(worldSpaceVertexNormal, dirToCam));
                value = 1.0 - value;
                value = pow(value, exponent);
                return value;
            } 

            float rimLight(half3 worldNormal, float3 worldPosition, half3 lightDirection)
            {
                half3 directionToCamera = normalize(_WorldSpaceCameraPos - worldPosition); 

                float rimMask = ceil(fresnel(directionToCamera, worldNormal, 2.0) - _RimThinness);
                float lightMask = dot(lightDirection, worldNormal);

                return rimMask * pow(lightMask, _RimThreshold);
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 textureColor = tex2D(_MainTex, i.uv);

                float steppedLight = SteppedLight(i.worldNormal, _WorldSpaceLightPos0.xyz) * _LightStepsStrength * _LightColor0;               
                float rim = rimLight(i.worldNormal, i.worldPosition, _WorldSpaceLightPos0.xyz);

                textureColor *= steppedLight + _Brightness + rim;

                return textureColor;
            }


            ENDCG
        }
    }
}
