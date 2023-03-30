Shader "01_FXStack/Shader_01_FXStack_Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineWidth("Outline Width", Range(0.0, 2.0)) = 0.2
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _NormalVSOriginDisplacement("Normal VS Origin displacement", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        // Outline Pass
        Pass
        {
            Tags { "RenderType"="Opaque" }
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            half _OutlineWidth;
            half4 _OutlineColor;
            half _NormalVSOriginDisplacement;


            v2f vert (appdata v)
            {
                v2f o;

                half3 directionFromOrigin = normalize(v.vertex.xyz);
                half3 displacementDirection = lerp(v.normal, directionFromOrigin, _NormalVSOriginDisplacement);
                float3 displacedPosition = v.vertex.xyz + (displacementDirection  * _OutlineWidth);

                float4 vertexPosition = float4(displacedPosition, 1.0);

                o.vertex = UnityObjectToClipPos(vertexPosition);

                

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }


        // Actual Object Pass
        Pass
        {
            Tags { "RenderType"="Opaque" }
            Cull Back

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
