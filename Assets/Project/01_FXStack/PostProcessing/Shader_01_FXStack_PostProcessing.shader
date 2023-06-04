Shader "01_FXStack/Shader_01_FXStack_PostProcessing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PrePass ("PrePass", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // Pass 0 - Invert Color
        Pass
        {
            Name "Mask"
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
            float4 _MainTex_ST;
            fixed4 _RimLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                return fixed4(1,1,1,1);             
            }
            ENDCG
        }

        // Pass 1 - Glow
        Pass
        {
            Name "Glow"
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

            sampler2D _MainTex, _Glow;
            float4 _MainTex_ST, _MainTex_TexelSize;
            float _Distance, _Sharpness;
            int _MinLevel;
            fixed4 _RimLightColor;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 Blur(sampler2D textureToBlur, float4 textureTexelSize, float2 uv, float distance, int minLevel)
            {
                fixed4 sum = fixed4(0.0, 0.0, 0.0, 0.0);

                sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y - 4.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.05;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y - 3.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.09;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y - 2.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.12;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y, 0, 6)) * 0.16;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y + 2.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.12;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y + 3.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.09;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y + 4.0 * 0.05 * distance * textureTexelSize.y, 0, minLevel)) * 0.05;
 
                sum += tex2Dlod(textureToBlur, half4(uv.x - 4.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.05;
				sum += tex2Dlod(textureToBlur, half4(uv.x - 3.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.09;
				sum += tex2Dlod(textureToBlur, half4(uv.x - 2.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.12;
				sum += tex2Dlod(textureToBlur, half4(uv.x, uv.y, 0, 6)) * 0.16;
				sum += tex2Dlod(textureToBlur, half4(uv.x + 2.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.12;
				sum += tex2Dlod(textureToBlur, half4(uv.x + 3.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.09;
				sum += tex2Dlod(textureToBlur, half4(uv.x + 4.0 * 0.05 * distance * textureTexelSize.x, uv.y, 0, minLevel)) * 0.05;

                return sum;
            }

            fixed4 frag (v2f i) : SV_Target
            {                                
                fixed4 color = tex2Dlod(_MainTex, float4(i.uv, 0, 0));
                
                fixed4 blur = Blur(_MainTex, _MainTex_TexelSize, i.uv, _Distance, _MinLevel);              

                //return blur;
                //return blur;
                //return color;
                //return (saturate(blur) - color) * _RimLightColor;
                return (pow(saturate(blur), _Sharpness) - color) * _RimLightColor;                
            }
            ENDCG
        }


        // Pass 2 - Additive
        Pass
        {
            Name "Additive"
            Blend One One
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

            sampler2D _MainTex, _CameraGlow;
            float4 _MainTex_ST, _MainTex_TexelSize;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                            
                fixed4 col = tex2D(_MainTex, i.uv);    
                return col;
            }
            ENDCG
        }
        
    }
}
