Shader "01_FXStack/Shader_01_FXStack_Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AmbientColor("Ambient Color", Color) = (0.25, 0.25, 0.35, 1.0)
        _AmbientStrength ("Ambient Strength", Range(0.0, 1.0)) = 0.1
        _SpecularStrength ("Specular Strength", Range(0.0, 10.0)) = 1.0
        _SpecularPow("Specular Pow", Range(0.0, 64.0)) = 32.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
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
                half3 worldNormal : TEXCOORD2;
                half3 directionalLightDir : TEXTCOORD4; 
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _AmbientColor;
            half _AmbientStrength;
            half _SpecularStrength, _SpecularPow;
            


            fixed4 computeAmbient(float4 lightColor)
            {
                fixed4 ambientColor = _AmbientStrength * lightColor;
                return ambientColor;
            }

            fixed4 computeDiffuse(float3 vertexPosition, half3 vertexNormal, float3 lightPosition, fixed4 lightColor)
            {
                half3 directionToLight = normalize(lightPosition - vertexPosition);
                half diffuseCoef = max(dot(vertexNormal, directionToLight), 0.0);

                fixed4 diffuseColor = diffuseCoef * lightColor;

                return diffuseColor;
            }

            fixed4 computeSpecular(half3 directionToCamera, half3 vertexNormal, half3 lightDirection, fixed4 lightColor)
            {
                half3 halfWayDir = normalize(directionToCamera + lightDirection);

                half specularCoef = max(dot(vertexNormal, halfWayDir), 0.0);
                specularCoef = pow(specularCoef, _SpecularPow);

                fixed4 specularColor = _SpecularStrength * specularCoef * lightColor;

                return specularColor;
            }

            fixed4 applyPhong(fixed4 baseColor, float3 vertexPosition, half3 vertexNormal)
            {
                half3 directionToCamera = normalize(_WorldSpaceCameraPos - vertexPosition); // Better results if computed in FRAGMENT


                // DIRECTIONAL LIGHT
                // _LightColor0 = DirectionalLight color
                half3 directionalLightDirection = _WorldSpaceLightPos0.xyz * (1 - _WorldSpaceLightPos0.w); 
                float3 directionalLightPosition = float3(0,0,0);

                fixed4 ambientColor = computeAmbient(_AmbientColor);
                fixed4 diffuseColor = computeDiffuse(vertexPosition, vertexNormal, directionalLightPosition, _AmbientColor);
                fixed4 specularColor = computeSpecular(directionToCamera, vertexNormal, directionalLightDirection, _AmbientColor);        

                // POINT LIGHT
                //half3 pointLightPosition = _WorldSpaceLightPos0.xyz * _WorldSpaceLightPos0.w; // Hmmmmm now compute spot light phong
                //diffuseColor += computeDiffuse(vertexPosition, vertexNormal, pointLightPosition, _AmbientColor);


                baseColor = (ambientColor + diffuseColor + specularColor) * baseColor;
                baseColor.w = 1.0;

                return baseColor;                
            }



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.directionalLightDir = _WorldSpaceLightPos0;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                
                baseColor = applyPhong(baseColor, i.worldPosition, i.worldNormal); 
                
                return baseColor;
            }
            ENDCG
        }
    }
}
