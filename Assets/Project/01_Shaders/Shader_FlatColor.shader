Shader "Classe_01/SHADER_FlatColor"
{
    Properties
    {
        _MainColor("Color", Color) = (1,1,1,1)
        _Tiling("Tiling", Vector) = (1,1,0,0)
        _MainTex("Texture", 2D) = "white"
    }
        SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VARIABLE TYPING:
            // uv -> float (coordenades)
            // vector -> half (colors HDR)
            // color & scalars -> fixed (colors normals)

            fixed4 _MainColor;
            float3 _Tiling;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                v.vertex.xyz *= _Tiling.z;

                //o.vertex = UnityObjectToClipPos(v.vertex); // This does the 3 lines bellow
                o.vertex = mul(UNITY_MATRIX_M, v.vertex);
                o.vertex.y *= o.vertex.y;
                o.vertex = mul(UNITY_MATRIX_V, o.vertex);
                o.vertex = mul(UNITY_MATRIX_P, o.vertex);
                
                o.color = _MainColor;
                o.uv = frac(v.texcoord * _Tiling);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {                
                return fixed4(i.uv, 0.0, 1.0);
            }

            ENDCG
        }
    }
}
