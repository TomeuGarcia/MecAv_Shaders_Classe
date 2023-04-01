Shader "01_FXStack/Shader_01_FXStack_Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (1.0, 0.0, 0.0, 1.0)
        _FresnelExponent("Fresnel Strength", Range(0.0, 5.0)) = 1.0      
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
            #pragma target 4.5            
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
                half3 worldNormal : NORMAL;

                float3 worldPosition : TEXCOORD1;
                half3 cameraForward : TEXCOORD2;
                float2 screenSpaceUV : TEXCOORD3;
                half3 dirToCam : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _FresnelExponent;
            fixed4 _OutlineColor;


            float fresnel(half3 dirToCam, half3 worldSpaceVertexNormal, half exponent, half3 camForward)
            {
                float value = saturate(dot(worldSpaceVertexNormal, dirToCam));
                //float value = saturate(dot(worldSpaceVertexNormal, -camForward));
                value = 1.0 - value;
                value = pow(value, exponent);
                return value;
            } 

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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz; // World Space VERTEX POSITION
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // World Space VERTEX NORMAL

                o.screenSpaceUV = getScreenSpaceUV(o.vertex);

                half4 cameraForwardObjectSpace = half4(0, 0, 1, 0);
                o.cameraForward =  normalize(mul(unity_CameraToWorld, cameraForwardObjectSpace).xyz); // World Space CAMERA NORMAL    

                o.dirToCam = normalize(_WorldSpaceCameraPos - o.worldPosition);  

                return o;
            }            

            fixed4 frag (v2f i) : SV_Target
            {                
                float2 uv = i.screenSpaceUV;
                uv.x *= _MainTex_ST.x;
                uv.y *= _MainTex_ST.y;

                // Panning
                uv.x += _Time.y * _MainTex_ST.z;
                uv.y += _Time.y * _MainTex_ST.w;


                fixed4 col = tex2D(_MainTex, uv);

                float interpolation = fresnel(i.dirToCam, i.worldNormal, _FresnelExponent, i.cameraForward);
                col.xyz = lerp(col.xyz, _OutlineColor.xyz, interpolation);
                
                return col;
            }

            ENDCG
        }
    }
}
