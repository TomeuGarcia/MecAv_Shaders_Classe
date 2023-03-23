Shader "01_FXStack/Shader_01_FXStack_Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _TopColor("Top Color", Color) = (0.9, 0.9, 0.9, 1.0)
        _BottomColor("Bottom Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColorOffset("Color Offset", Range(-1.0, 1.0)) = 0.0    
        _ColorContrast("Color Contrast", Range(0.0, 10.0)) = 1.0    

        _SwingSpeed("Swing Speed", Range(0.0, 4.0)) = 1.0
        _SwingAmplitude("Swing Amplitude", Range(0.0, 4.0)) = 1.0
        _SwingOffset("Swing Offset", Range(0.0, 10.0)) = 3.0
    }
    SubShader
    {
        Tags { "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType"="TransparentCutout"  }
        Blend One OneMinusSrcAlpha
        ZWrite Off        
        Cull Off

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
            float4 _MainTex_ST;
            fixed4 _TopColor, _BottomColor;
            float _ColorOffset, _ColorContrast;
            half _SwingSpeed,_SwingAmplitude, _SwingOffset;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float4 objectPos = v.vertex;
                objectPos += sin((_Time.y + (o.uv.x * _SwingOffset))  * _SwingSpeed) * o.uv.y * _SwingAmplitude;
                
                o.vertex = UnityObjectToClipPos(objectPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float interpolation = i.uv.y;
                interpolation = saturate(interpolation + _ColorOffset);
                interpolation = saturate(pow(interpolation, _ColorContrast));          

                fixed4 col = tex2D(_MainTex, i.uv);
                
                col.rbg *= col.a;
                col.rgb *= lerp(_BottomColor, _TopColor, interpolation);        

                if (col.a < 0.5) discard;        
                
                return col;
            }
            ENDCG
        }
    }
}
