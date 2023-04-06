Shader "01_FXStack/Shader_01_FXStack_Displacement"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxHeight ("Displacement Max Height", Range(0.0, 10.0)) = 1.0
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

                float3 worldPosition : TEXCOORD1;
                half3 worldNormal : TEXCOORD2;
                float displacement : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _MaxHeight;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;

                float displacement = tex2Dlod(_MainTex, float4(o.uv, 0, 0)).x;    
                o.displacement = displacement;
                displacement *= _MaxHeight;            

                o.worldPosition += o.worldNormal * displacement;
                
                o.vertex = UnityWorldToClipPos(float4(o.worldPosition, 1));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed col  = saturate(i.displacement);

                return fixed4(col, col, col, 1);
            }
            ENDCG
        }
    }
}
