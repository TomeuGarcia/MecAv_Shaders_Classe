Shader "01_FXStack/Shader_01_FXStack_Normals"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ObjectOrWorldNormals ("Object or World Normals", Range(0.0, 1.0)) = 1.0
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
                half3 worldNormal : NORMAL;
                half3 objectNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ObjectOrWorldNormals;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.objectNormal = normalize(v.normal); // Object Space
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // World Space

                half3 cameraForwardObjectSpace = half3(0,0,1);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(0,0,0,1);
                col.xyz = lerp(i.objectNormal, i.worldNormal, _ObjectOrWorldNormals);

                return col;
            }
            ENDCG
        }
    }
}
