
fixed4 computeAmbient(float4 lightColor, float ambientStrength)
{
    fixed4 ambientColor = ambientStrength * lightColor;
    return ambientColor;
}

fixed4 computeDiffuse(float3 vertexPosition, half3 vertexNormal, float3 lightPosition, fixed4 lightColor)
{
    half3 directionToLight = normalize(lightPosition - vertexPosition);
    half diffuseCoef = saturate(dot(vertexNormal, directionToLight));

    fixed4 diffuseColor = diffuseCoef * lightColor;

    return diffuseColor;
}

fixed4 computeSpecular(half3 directionToCamera, half3 vertexNormal, half3 lightDirection, fixed4 lightColor, float specularStrength, float specularPow)
{
    half3 halfWayDir = normalize(directionToCamera + lightDirection);

    half specularCoef = saturate(dot(vertexNormal, halfWayDir));
    specularCoef = pow(specularCoef, specularPow * 1000.0);

    fixed4 specularColor = specularStrength * specularCoef * lightColor;

    return specularColor;
}

fixed4 applyPhong(fixed4 baseColor, float3 vertexPosition, half3 vertexNormal, float3 directionToCamera, float3 lightPosition, half3 lightDirection, fixed4 lightColor, 
                    float ambientStrength, float specularStrength, float specularPow)
{
    fixed4 ambientColor = computeAmbient(lightColor, ambientStrength);
    fixed4 diffuseColor = computeDiffuse(vertexPosition, vertexNormal, lightPosition, lightColor);
    fixed4 specularColor = computeSpecular(directionToCamera, vertexNormal, lightDirection, lightColor, specularStrength, specularPow);        

    baseColor = ambientColor + (diffuseColor * baseColor) + specularColor;
    baseColor.w = 1.0;


    return baseColor;
}
