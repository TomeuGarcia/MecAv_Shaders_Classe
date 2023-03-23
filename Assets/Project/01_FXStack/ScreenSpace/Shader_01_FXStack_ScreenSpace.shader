Shader "01_FXStack/Shader_01_FXStack_ScreenSpace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenSpaceUV : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // Clip space vertex to transpose coordinates
                o.screenSpaceUV = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Divide screen position xy by screen position w
                float2 screenSpaceUV = i.screenSpaceUV.xy / i.screenSpaceUV.w;

                // Divide screen params to get aspect ratio
                float2 ratio = _ScreenParams.x / _ScreenParams.y;
                screenSpaceUV.x *= ratio;

                fixed4 col = tex2D(_MainTex, screenSpaceUV);

                return col;                

                // Coordinate x * aspect
                
            }
            ENDCG
        }
    }
}
