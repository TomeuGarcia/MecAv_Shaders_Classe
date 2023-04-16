Shader "01_FXStack/Shader_01_FXStack_Coordinates"
{
        Properties
    {
        _MainTex ("Texture A", 2D) = "white" {}
        _MainTexB ("Texture B", 2D) = "white" {}

        _MaskAdd("Vortex Size Increment", Range(0, 0.5)) = 0.1
        _MaskPow("Vortex Spread", Range(1, 20)) = 10
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
            #include "../../MyShaderLibraries/MyUVFunctions.cginc"

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

            sampler2D _MainTex, _MainTexB;
            float4 _MainTex_ST, _MainTex_B_ST;
            fixed _MaskAdd, _MaskPow;



            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;            

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // UV of water panning texture
                float2 uv_Panning = (i.uv *_MainTex_ST.xy)  + (_MainTex_ST.zw * _Time.y);

                // Center UVs for polar                
                float2 uv_Vortex = i.uv;                
                uv_Vortex *= 2.0;
                uv_Vortex = frac(uv_Vortex);
                uv_Vortex -= 0.5;                

                // Before computing polar, Spherical mask from center (to lerp after with teh base texture)
                fixed mask = distance(fixed2(0,0), uv_Vortex);
                mask = saturate(mask);
                mask = 1.0 - mask;
                mask += _MaskAdd;
                mask = pow(mask, _MaskPow);
                mask = saturate(mask);

                // Transform uv vortex texture to polar
                uv_Vortex = cartesianToPolar(uv_Vortex, PI2);


                // Apply effects on polar
                uv_Vortex.x += _Time.y * 0.2;
                uv_Vortex.y += _Time.y * 0.1;
                uv_Vortex = frac(uv_Vortex);    

                //return fixed4(mask, mask, mask, 1);
                // Go back to Cartesian
                uv_Vortex = polarToCartesian(uv_Vortex, PI2);               
                uv_Vortex = min(uv_Vortex, uv_Panning);

                //return fixed4(uv_Vortex, 0, 1);

                // Sample both textures with both UVs
                fixed4 panningColor = tex2D(_MainTex, uv_Panning);
                fixed4 vortexColor = tex2D(_MainTexB, uv_Vortex);


                // Return interpolation between the 2 colors using the mask
                return lerp(panningColor, vortexColor, mask);
            }
            ENDCG
        }
    }
}
