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


            float2 getScreenSpaceUV(float4 clipPosVertex)
            {
                // Clip space vertex to transpose coordinates
                float4 screenPos = ComputeScreenPos(clipPosVertex);                

                // Divide screen position xy by screen position w
                float2 screenSpaceUV = screenPos.xy / screenPos.w;

                // Divide screen params to get aspect ratio
                float2 ratio = _ScreenParams.x / _ScreenParams.y;
                screenSpaceUV.x *= ratio;
                
                return screenSpaceUV;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.screenSpaceUV.xy = getScreenSpaceUV(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.screenSpaceUV.xy;
                uv.x *= _MainTex_ST.x;
                uv.y *= _MainTex_ST.y;

                fixed4 col = tex2D(_MainTex, uv);

                return col;                                
            }

            ENDCG
        }
    }
}
