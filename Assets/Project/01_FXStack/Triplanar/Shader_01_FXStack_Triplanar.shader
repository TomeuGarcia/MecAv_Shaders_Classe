Shader "01_FXStack/Shader_01_FXStack_Triplanar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _TextureUp ("Texture Up", 2D) = "white" {}
        _TextureSides ("Texture Sides", 2D) = "white" {}
        _Falloff("Blend FallOff", Range(1.0, 8.0)) = 5.0
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
            #include "../../MyShaderLibraries/MyTriplanar.cginc"


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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Falloff;
            sampler2D _TextureUp;
            sampler2D _TextureSides;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Calculate world position and assign it
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Calculate world normal and assign it
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 triplanarColor = getSeamlessTriplanarColor(i.worldPosition, i.worldNormal, _TextureUp, _TextureSides, _TextureSides, _Falloff);

                return triplanarColor;
            }

            ENDCG
        }
    }
}
