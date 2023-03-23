Shader "02_Classe/Shader_UV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ST ("Tiling & Offset", Vector) = (1, 1, 0, 0)

        _PanningX ("Panning X", Range(-10, 10)) = 0
        _PanningY ("Panning Y", Range(-10, 10)) = 0



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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;                                        
            };

            sampler2D _MainTex;
            float4 _ST;
            fixed _PanningX, _PanningY;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                _PanningX *= _Time.y;
                _PanningY *= _Time.y;
                float2 panning = float2(_PanningX, _PanningY);

                uv = frac((uv * _ST.xy) + _ST.zw + panning);

                //return fixed4(uv, 0, 1);
                return tex2D(_MainTex, uv);
            }
            ENDCG
        }
    }
}
