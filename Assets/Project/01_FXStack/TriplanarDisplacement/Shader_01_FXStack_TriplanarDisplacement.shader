Shader "01_FXStack/Shader_01_FXStack_TriplanarDisplacement"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _SidesTex ("Sides Texture", 2D) = "white" {}
        _TopTex ("Top Texture", 2D) = "white" {}
        _TriplanarFalloff("Triplanar Falloff", Range(0.01, 16.0)) = 1.0

        _HeightMapTex ("Height Map Texture", 2D) = "white" {}
        _MaxHeight ("Displacement Max Height", Range(0.0, 10.0)) = 1.0

        _TexelDist("Texel Dist", Float) = 0.01

        _XZdirection("Invert X & Z direction", Range(-1, 1)) = -1
        _NormalsVSTrplanar("Normals VS Triplanar Color", Range(0, 1)) = -1

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

            sampler2D _MainTex, _HeightMapTex;
            float4 _MainTex_ST, _HeightMapTex_TexelSize;
            float _MaxHeight;

            fixed _TexelDist;

            half _XZdirection;

            sampler2D _SidesTex, _TopTex;
            fixed _TriplanarFalloff;
            half _NormalsVSTrplanar;


            v2f vert (appdata v)
            {
                v2f o;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);                
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;

                float displacement = tex2Dlod(_HeightMapTex, float4(o.uv, 0, 0)).x;    
                displacement *= _MaxHeight;            

                o.worldPosition += o.worldNormal * displacement;
                
                o.vertex = UnityWorldToClipPos(float4(o.worldPosition, 1));
                
                o.worldNormal = filterNormal(_HeightMapTex, float4(o.uv, 0, 0), _HeightMapTex_TexelSize.x, _TexelDist, _MaxHeight);
                o.worldNormal.x *= _XZdirection;
                o.worldNormal.z *= _XZdirection;
                o.worldNormal = UnityObjectToWorldNormal(o.worldNormal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 triplanarColor = getSeamlessTriplanarColor(i.worldPosition, i.worldNormal, _TopTex, _SidesTex, _SidesTex, _TriplanarFalloff);
                fixed4 normalsColor = fixed4(i.worldNormal, 1);

                return lerp(normalsColor, triplanarColor, _NormalsVSTrplanar);
            }
            ENDCG
        }
    }
}
