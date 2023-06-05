Shader "Unlit/TestingShaders"
{
    Properties
    {
        _ObjectColor("Object Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _Normal_ObjectVSWorld ("NORMAL Object VS World", Range(0,1)) = 0
        _OutlineDisplacement ("Outline displacement", Range(0,5)) = 1
        _OutlineColorSpeed ("Outline color speed", Range(0,5)) = 1
        _LightStepsInverse ("Light Steps Inverse", Range(0.001,1)) = 0.3
        _RimLightExponent ("Rim Light Exponent", Range(0.001,20)) = 1.0
        _RimLightColor ("Rim Light Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {
            Cull Front

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
                half3 normal : NORMAL;
                half3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlineDisplacement, _OutlineColorSpeed;



            float sin01(float t)
            {
                return (sin(t) + 1.0) / 2.0;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                half3 displacementDirection = v.normal * _OutlineDisplacement;
                o.vertex = UnityObjectToClipPos(v.vertex + displacementDirection);

                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 outlienColor = fixed4(1,1,1,1);

                float s = sin01(_Time.y * _OutlineColorSpeed);
                
                outlienColor.x = s;
                outlienColor.z = 1.0 - s;

                return outlienColor;
            }
            ENDCG
        }


        Pass
        {
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
                half3 normal : NORMAL;
                half3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };

            fixed4 _ObjectColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Normal_ObjectVSWorld;
            float _LightStepsInverse;
            float _RimLightExponent;
            fixed4 _RimLightColor;



            fixed4 GetDiffuseColor(half3 fragmentWorldNormal, half3 lightDirection, fixed4 lightColor)
            {
                float NdotLD = saturate(dot(-fragmentWorldNormal, lightDirection));
                fixed4 diffuseColor =  NdotLD * lightColor;
                return diffuseColor;
            }


            fixed4 GetSteppedDiffuseColor(half3 fragmentWorldNormal, half3 lightDirection, fixed4 lightColor, float stepsInverse)
            {
                float NdotLD = saturate(dot(-fragmentWorldNormal, lightDirection));

                NdotLD = floor(NdotLD / stepsInverse) * stepsInverse;

                fixed4 diffuseColor =  NdotLD * lightColor;               
                return diffuseColor;
            }

            float GetFresnel(float3 sourcePosition, float3 fragmentWorldPosition, half3 fragmentWorldNormal, float exponent)
            {
                half3 fragmentToCamera = normalize(sourcePosition - fragmentWorldPosition);
                float fresnel = saturate(dot(fragmentToCamera, fragmentWorldNormal));
                fresnel = 1 - fresnel;
                fresnel = pow(fresnel, exponent);

                return fresnel;
            }

            float GetRimMask(float3 lightPosition, float3 fragmentWorldPosition, half3 fragmentWorldNormal, float fresnelExponent, float3 cameraPosition, half3 lightDirection)
            {
                float fresnel = GetFresnel(cameraPosition, fragmentWorldPosition, fragmentWorldNormal, fresnelExponent);

                float NdotLD = saturate(dot(-fragmentWorldNormal, lightDirection)); 
                float rimMask = fresnel * NdotLD;
                
                rimMask = step(0.5, rimMask);

                return rimMask;
            }




            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);


                fixed4 worldNormalColor = fixed4(i.worldNormal, 1.0);
                fixed4 objectNormalColor = fixed4(i.normal, 1.0);
                fixed4 normalColor = lerp(objectNormalColor, worldNormalColor, _Normal_ObjectVSWorld);

                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed4 lightColor = fixed4(1, 1, 1, 1);
                fixed4 diffuseColor = _ObjectColor * GetSteppedDiffuseColor(i.worldNormal, lightDir, lightColor, _LightStepsInverse);

                float3 cameraPosition = _WorldSpaceCameraPos;
                float3 rimSource = float3(-100, 100, -100);
                float exponent = _RimLightExponent;
                float rimMask = GetRimMask(rimSource, i.worldPosition, i.worldNormal, exponent, cameraPosition, lightDir);
                

                fixed4 finalColor = diffuseColor + (_RimLightColor * rimMask);

                return finalColor;
            }
            ENDCG
        }


    }
}
