
float fresnel(half3 directionToCamera, half3 worldSpaceVertexNormal, half exponent)
{
    float value = saturate(dot(worldSpaceVertexNormal, directionToCamera));
    value = 1.0 - value;
    value = pow(value, exponent);
    return value;
} 