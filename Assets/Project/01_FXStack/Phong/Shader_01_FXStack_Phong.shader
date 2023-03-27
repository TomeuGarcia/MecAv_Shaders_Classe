Shader "Unlit/Shader_01_FXStack_Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AmbientStrength ("Ambient Strength", Range(0.0, 1.0)) = 0.1
        _SpecularExp ("Specular Strength", Range(0.0, 10.0)) = 1.0
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

                half3 worldNormal : TEXCOORD1;
                half3 dirToCam : TEXTCOORD2;
                half3 directionalLightDir : TEXTCOORD3; 
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AmbientStrength, _SpecularExp;
            


            fixed4 computeAmbient()
            {

            }

            fixed4 computeDiffuse()
            {

            }

            fixed4 computeSpecular()
            {
                
            }

            fixed4 computePhong()
            {
                
            }



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.dirToCam = normalize(_WorldSpaceCameraPos - worldPosition);

                o.directionalLightDir = _WorldSpaceLightPos0;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed4 ambientColor = _LightColor0 * _AmbientStrength;
                 
                return fixed4(abs(i.directionalLightDir), 1);

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
