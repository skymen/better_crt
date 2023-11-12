/////////////////////////////////////////////////////////
// Minimal sample WebGPU shader. This just outputs a blue
// color to indicate WebGPU is in use (rather than one of
// the WebGL shader variants).

%%FRAGMENTINPUT_STRUCT%%
/* input struct contains the following fields:
fragUV : vec2<f32>
fragPos : vec4<f32>
fn c3_getBackUV(fragPos : vec2<f32>, texBack : texture_2d<f32>) -> vec2<f32>
fn c3_getDepthUV(fragPos : vec2<f32>, texDepth : texture_depth_2d) -> vec2<f32>
*/
%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

//%//%SAMPLERBACK_BINDING%//% var samplerBack : sampler;
//%//%TEXTUREBACK_BINDING%//% var textureBack : texture_2d<f32>;

//%//%SAMPLERDEPTH_BINDING%//% var samplerDepth : sampler;
//%//%TEXTUREDEPTH_BINDING%//% var textureDepth : texture_depth_2d;

/* Uniforms are:
uAngle: angle of the shine, 0.0-360.0
uIntensity: how hard to mix the shine with the image, 0.0-1.0
uColor: the color of the shine, vec4
uSize: the size of the shine in percent based on diameter, 0.0-1.0
uProgress: the progress of the shine, 0.0-1.0
uHardness: how hard the shine is, 0 is smooth, 1 is a hard edge , 0.0-1.0
 */

//<-- shaderParams -->
/* gets replaced with:

struct ShaderParams {

	floatParam : f32,
	colorParam : vec3<f32>,
	// etc.

};

%//%SHADERPARAMS_BINDING%//% var<uniform> shaderParams : ShaderParams;
*/


%%C3PARAMS_STRUCT%%
/* c3Params struct contains the following fields:
srcStart : vec2<f32>,
srcEnd : vec2<f32>,
srcOriginStart : vec2<f32>,
srcOriginEnd : vec2<f32>,
layoutStart : vec2<f32>,
layoutEnd : vec2<f32>,
destStart : vec2<f32>,
destEnd : vec2<f32>,
devicePixelRatio : f32,
layerScale : f32,
layerAngle : f32,
seconds : f32,
zNear : f32,
zFar : f32,
isSrcTexRotated : u32
fn c3_srcToNorm(p : vec2<f32>) -> vec2<f32>
fn c3_normToSrc(p : vec2<f32>) -> vec2<f32>
fn c3_srcOriginToNorm(p : vec2<f32>) -> vec2<f32>
fn c3_normToSrcOrigin(p : vec2<f32>) -> vec2<f32>
fn c3_clampToSrc(p : vec2<f32>) -> vec2<f32>
fn c3_clampToSrcOrigin(p : vec2<f32>) -> vec2<f32>
fn c3_getLayoutPos(p : vec2<f32>) -> vec2<f32>
fn c3_srcToDest(p : vec2<f32>) -> vec2<f32>
fn c3_clampToDest(p : vec2<f32>) -> vec2<f32>
fn c3_linearizeDepth(depthSample : f32) -> f32
*/

//%//%C3_UTILITY_FUNCTIONS%//%
/*
fn c3_premultiply(c : vec4<f32>) -> vec4<f32>
fn c3_unpremultiply(c : vec4<f32>) -> vec4<f32>
fn c3_grayscale(rgb : vec3<f32>) -> f32
fn c3_getPixelSize(t : texture_2d<f32>) -> vec2<f32>
fn c3_RGBtoHSL(color : vec3<f32>) -> vec3<f32>
fn c3_HSLtoRGB(hsl : vec3<f32>) -> vec3<f32>
*/

fn curve(uv: vec2<f32>) -> vec2<f32> {
    var uv1 = (uv - 0.5) * (2.0 + shaderParams.barrelDistortionZoom);
    let uva = atan2(uv1.x, uv1.y);
    let uvd = length(uv1);
    let k = shaderParams.barrelDistortionStrength;
    uv1 = vec2(sin(uva), cos(uva)) * uvd * (1.0 + k * uvd * uvd);
    return (uv1 / 2.0) + 0.5;
}

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
	var output : FragmentOutput;
    let iTime = c3Params.seconds;
    let redOffset = vec2<f32>(shaderParams.redOffsetX, shaderParams.redOffsetY);
    let greenOffset = vec2<f32>(shaderParams.greenOffsetX, shaderParams.greenOffsetY);
    let blueOffset = vec2<f32>(shaderParams.blueOffsetX, shaderParams.blueOffsetY);

    var uv = curve(input.fragUV);
    var col : vec3<f32>;
    let x = shaderParams.distortionStrength
		* sin(shaderParams.distortionSpeed * 0.3 * iTime + uv.y * 21.0 * shaderParams.distortionFrequency)
		* sin(shaderParams.distortionSpeed * 0.7 * iTime + uv.y * 29.0 * shaderParams.distortionFrequency)
		* sin(0.3 + shaderParams.distortionSpeed * 0.33 * iTime + uv.y * 31.0 * shaderParams.distortionFrequency)
		* 0.0017;

		col.r = textureSample(textureFront, samplerFront, vec2<f32>(x + uv.x + redOffset.x, uv.y + redOffset.y)).r + 0.05;
		col.g = textureSample(textureFront, samplerFront, vec2<f32>(x + uv.x + greenOffset.x, uv.y + greenOffset.y)).g + 0.05;
		col.b = textureSample(textureFront, samplerFront, vec2<f32>(x + uv.x + blueOffset.x, uv.y + blueOffset.y)).b + 0.05;

		col.r += shaderParams.bloomIntensity * 0.08 * textureSample(textureFront, samplerFront, vec2<f32>(0.75 * (x + 0.025), 0.75 * -0.027) + vec2<f32>(x + uv.x + redOffset.x, uv.y + redOffset.y)).r;
		col.g += shaderParams.bloomIntensity * 0.05 * textureSample(textureFront, samplerFront, vec2<f32>(0.75 * (x - 0.022), 0.75 * -0.02)  + vec2<f32>(x + uv.x + greenOffset.x, uv.y + greenOffset.y)).g;
		col.b += shaderParams.bloomIntensity * 0.08 * textureSample(textureFront, samplerFront, vec2<f32>(0.75 * (x - 0.02), 0.75 * -0.018)  + vec2<f32>(x + uv.x + blueOffset.x, uv.y + blueOffset.y)).b;


    col = clamp(col * 0.6 + 0.4 * col * col * 1.0, vec3<f32>(0.0), vec3<f32>(1.0));
    let vig = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
    col *= vec3<f32>(pow(vig, 0.3));
    col *= shaderParams.colorAdjustment;
    col *= 2.8;

    let scans = clamp(0.35 + 0.35 * sin(3.5 * iTime + uv.y * shaderParams.resolutionY * 1.5), 0.0, 1.0);
    let s = pow(scans, shaderParams.scanlinesIntensity);
    col = col * vec3<f32>(0.4 + 0.7 * s);
    col *= 1.0 + 0.01 * sin(110.0 * iTime);

    if (uv.x < 0.0 || uv.x > 1.0) {
        col *= 0.0;
    }
    if (uv.y < 0.0 || uv.y > 1.0) {
        col *= 0.0;
    }

    col *= 1.0 - shaderParams.distortIntensity * vec3<f32>(clamp((fract(input.fragPos.x * 0.5) * 2.0 - 1.0), 0.0, 1.0));
		output.color = vec4<f32>(col, 1.0);
		return output;
}