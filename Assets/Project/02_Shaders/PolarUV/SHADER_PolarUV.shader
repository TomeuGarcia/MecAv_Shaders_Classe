Shader "02_Classe/SHADER_PolarUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ST ("Tiling & Offset", Vector) = (1, 1, 0, 0)

        _PanningX ("Panning X", Range(-10, 10)) = 0
        _PanningY ("Panning Y", Range(-10, 10)) = 0

        _SpinSpeed ("Spin Speed", Range(-4, 4)) = 0
        _SucktionSpeed ("Sucktion Speed", Range(-4, 4)) = 0

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
            #define PI2 6.283185307179

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
            fixed _SpinSpeed, _SucktionSpeed;

            float2 cartesianToPolar(float2 cartesianCoords)
            {
                float distance = length(cartesianCoords);
                float angle = atan2(cartesianCoords.y, cartesianCoords.x);
                return float2(angle / PI2, distance);
            }

            
            float2 polarToCartesian(float2 polarCoords)
            {
                float2 cartesianCoords;
                sincos(polarCoords.x * PI2, cartesianCoords.y, cartesianCoords.x);
                return cartesianCoords * polarCoords.y;
            }


            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Base UV setup
                float2 uv = i.uv;
                
                // Apply Tiling, Offset and Panning
                _PanningX *= _Time.y;
                _PanningY *= _Time.y;
                float2 panning = float2(_PanningX, _PanningY);
                uv = (uv * _ST.xy) + _ST.zw + panning;


                // Cartesian to Polar
                // First center UV
                uv = (uv - 0.5) * 2.0;
                uv = cartesianToPolar(uv);

                // Additional modifications
                uv.x += _Time.y * _SpinSpeed;
                uv.y += _Time.y * _SucktionSpeed;                

                // Go back to Cartesian
                uv = polarToCartesian(uv);

                // Final correction
                uv = frac(uv);

                // Output color
                //return fixed4(uv, 0, 1);
                return tex2D(_MainTex, uv);
            }
            ENDCG
        }
    }
}
