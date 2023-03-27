Shader "01_FXStack/Shader_01_FXStack_Triplanar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _TextureUp ("Texture Up", 2D) = "white" {}
        _TextureSides ("Texture Sides", 2D) = "white" {}
        _Falloff("Blend FallOff", Range(0.0, 5.0)) = 0.25
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Falloff;
            sampler2D _TextureUp;
            sampler2D _TextureSides;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Calculate world position and assign it
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Calculate world normal and assign it
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 getTriplanarColor(float3 worldPosition, half3 worldNormal, sampler2D textureUp, sampler2D textureRight, sampler2D textureForward, fixed falloff)
            {
                // Calculate uv up (xz) and assign as uv_up
                float2 uv_up = worldPosition.xz;

                // Calculate uv right (yz) and assign as uv_right
                float2 uv_right = worldPosition.yz;

                // Calculate uv forward (yx) and assign as uv_forward
                float2 uv_forward = worldPosition.yx;


                // tex2D(textureUp, uv_up)
                fixed4 color_up = tex2D(textureUp, uv_up);

                // tex2D(textureRight, uv_right)
                fixed4 color_right = tex2D(textureRight, uv_right);

                // tex2D(textureForward, uv_forward)
                fixed4 color_forward = tex2D(textureForward, uv_forward);


                half3 weights;
                weights.y = pow(abs(dot(worldNormal, half3(0, 1, 0))), falloff);
                weights.x = pow(abs(dot(worldNormal, half3(1, 0, 0))), falloff);
                weights.z = pow(abs(dot(worldNormal, half3(0, 0, 1))), falloff);
                weights = normalize(weights);


                // Sampled Color up * abs(normal.y)                                
                color_up *= weights.y;

                // Sampled Color right * abs(normal.x)                
                color_right *= weights.x;

                // Sampled Color forward * abs(normal.z)
                color_forward *= weights.z;

                return color_up + color_right + color_forward;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 triplanarColor = getTriplanarColor(i.worldPosition, i.worldNormal, _TextureUp, _TextureSides, _TextureSides, _Falloff);

                return triplanarColor;
            }

            ENDCG
        }
    }
}
