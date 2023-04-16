
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

float2 cartesianToPolar(float2 cartesianCoords, float pi2)
{
    float distance = length(cartesianCoords);
    float angle = atan2(cartesianCoords.y, cartesianCoords.x);
    return float2(angle / pi2, distance);
}


float2 polarToCartesian(float2 polarCoords, float pi2)
{
    float2 cartesianCoords;
    sincos(polarCoords.x * pi2, cartesianCoords.y, cartesianCoords.x);
    return cartesianCoords * polarCoords.y;
}