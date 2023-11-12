#version 300 es

// Sample WebGL 2 shader. This just outputs a green color
// to indicate WebGL 2 is in use. Notice that WebGL 2 shaders
// must be written with '#version 300 es' as the very first line
// (no linebreaks or comments before it!) and have updated syntax.

in mediump vec2 vTex;
out lowp vec4 outColor;

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define highmedp highp
#else
#define highmedp mediump
#endif

precision lowp float;

uniform lowp sampler2D samplerFront;
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
uniform lowp sampler2D samplerBack;
uniform lowp sampler2D samplerDepth;
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
uniform mediump vec2 pixelSize;
uniform mediump float layerScale;
uniform mediump float layerAngle;
uniform mediump float devicePixelRatio;
uniform mediump float zNear;
uniform mediump float zFar;
uniform highmedp float seconds;

//<-- UNIFORMS -->


vec2 curve(vec2 uv)
{
  uv = (uv - 0.5) * (2.0 + barrelDistortionZoom);
	float uva = atan(uv.x, uv.y);
	float uvd = sqrt(dot(uv, uv));
	//k = negative for pincushion, positive for barrel
	float k = barrelDistortionStrength;
	uvd = uvd*(1.0 + k*uvd*uvd);
	uv = vec2(sin(uva), cos(uva))*uvd;
	uv = (uv / 2.0) + 0.5;
	return uv;
}

void main(void)
{
    float iResolutionX = resolutionX;
    float iResolutionY = resolutionY;
    float iTime = seconds;
		// New Uniforms
		vec2 redOffset = vec2(redOffsetX, redOffsetY);
		vec2 greenOffset = vec2(greenOffsetX, greenOffsetY);
		vec2 blueOffset = vec2(blueOffsetX, blueOffsetY);

    vec2 uv = curve(vTex);
    vec3 col;
	float x = distortionStrength * sin(distortionSpeed * 0.3 * iTime + uv.y * 21.0 * distortionFrequency) * sin(distortionSpeed * 0.7 * iTime + uv.y * 29.0 * distortionFrequency) * sin(0.3 + distortionSpeed * 0.33 * iTime + uv.y * 31.0 * distortionFrequency) * 0.0017;

    col.r = texture(samplerFront, vec2(x + uv.x + redOffset.x, uv.y + redOffset.y)).x + 0.05;
    col.g = texture(samplerFront, vec2(x + uv.x + greenOffset.x, uv.y + greenOffset.y)).y + 0.05;
    col.b = texture(samplerFront, vec2(x + uv.x + blueOffset.x, uv.y + blueOffset.y)).z + 0.05;

    col.r += bloomIntensity * 0.08 * texture(samplerFront, 0.75 * vec2(x + 0.025, -0.027) + vec2(x + uv.x + redOffset.x, uv.y + redOffset.y)).x;
    col.g += bloomIntensity * 0.05 * texture(samplerFront, 0.75 * vec2(x - 0.022, -0.02) + vec2(x + uv.x + greenOffset.x, uv.y + greenOffset.y)).y;
    col.b += bloomIntensity * 0.08 * texture(samplerFront, 0.75 * vec2(x - 0.02, -0.018) + vec2(x + uv.x + blueOffset.x, uv.y + blueOffset.y)).z;

    col = clamp(col * 0.6 + 0.4 * col * col * 1.0, 0.0, 1.0);
    float vig = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
    col *= vec3(pow(vig, 0.3));
    col *= colorAdjustment;
    col *= 2.8;
    float scans = clamp(0.35 + 0.35 * sin(3.5 * iTime + uv.y * iResolutionY * 1.5), 0.0, 1.0);
    float s = pow(scans, scanlinesIntensity);
    col = col * vec3(0.4 + 0.7 * s);
    col *= 1.0 + 0.01 * sin(110.0 * iTime);
    if (uv.x < 0.0 || uv.x > 1.0) col *= 0.0;
    if (uv.y < 0.0 || uv.y > 1.0) col *= 0.0;
    col *= 1.0 - distortIntensity * vec3(clamp((mod(gl_FragCoord.x, 2.0) - 1.0) * 2.0, 0.0, 1.0));
    outColor = vec4(col, 1.0);
}
