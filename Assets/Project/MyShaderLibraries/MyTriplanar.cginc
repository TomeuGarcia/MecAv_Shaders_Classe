

fixed4 getTriplanarColor(float3 worldPosition, half3 worldNormal, sampler2D textureUp, sampler2D textureRight, sampler2D textureForward, fixed falloff)
{
    // Calculate uv up (xz) and assign as uv_up
    float2 uv_up = worldPosition.xz;

    // Calculate uv right (yz) and assign as uv_right
    float2 uv_right = worldPosition.yz;

    // Calculate uv forward (yx) and assign as uv_forward
    float2 uv_forward = worldPosition.xy;


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

fixed4 getSeamlessTriplanarColor(float3 worldPosition, half3 worldNormal, sampler2D textureUp, sampler2D textureRight, sampler2D textureForward, fixed falloff)
{                
    half3 absoluteWorldNormal = pow(abs(worldNormal), falloff);
    half3 mappedNormal = dot(absoluteWorldNormal, half3(1, 1, 1));
    half3 weights = absoluteWorldNormal / mappedNormal;               
    

    float2 uv_up = worldPosition.xz;
    float2 uv_right = worldPosition.yz;
    float2 uv_forward = worldPosition.xy;


    fixed4 color_up = tex2D(textureUp, uv_up);
    fixed4 color_right = tex2D(textureRight, uv_right);
    fixed4 color_forward = tex2D(textureForward, uv_forward);


    color_up *= weights.y;
    color_right *= weights.x;
    color_forward *= weights.z;

    return color_up + color_right + color_forward;
}



half3 filterNormal(sampler2D heightMap, float4 uv, float texelSize, fixed texelDist, fixed maxHeight)
{
    float4 h;
    h.x = tex2Dlod(heightMap, uv + float4(texelSize * float2(0, -1 * texelDist), 0, 0)).x * maxHeight;
    h.y = tex2Dlod(heightMap, uv + float4(texelSize * float2(-1 * texelDist, 0), 0, 0)).x * maxHeight;
    h.z = tex2Dlod(heightMap, uv + float4(texelSize * float2(1 * texelDist, 0), 0, 0)).x * maxHeight;
    h.w = tex2Dlod(heightMap, uv + float4(texelSize * float2(0, 1 * texelDist), 0, 0)).x * maxHeight;

    float3 n;
    n.z = h.w - h.x;
    n.x = h.z - h.y;
    n.y = 2;
    return normalize(n);
}