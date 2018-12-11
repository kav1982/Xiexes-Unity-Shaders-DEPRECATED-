#include "UnityCG.cginc"
#include "AutoLight.cginc"
 
struct appdata {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};
 
struct v2f {
	float4 vertex : POSITION;
	float4 color : COLOR;
	float2 uv : TEXCOORD0;
};

float _OutlineThickness;
float4 _OutlineColor;
sampler2D _OutlineTextureMap;

v2f vert(appdata v) {
	v2f o;
	float4 outlineMultiMap = tex2Dlod(_OutlineTextureMap, float4(v.uv, 0, 0)); //sample from the first mip level 

	float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
	float dist = 1/distance(worldPos, _WorldSpaceCameraPos);

	float outlineWidth = _OutlineThickness * 0.005 * outlineMultiMap.r * min(distance(worldPos,_WorldSpaceCameraPos)*3, 1);
	v.vertex.xyz += normalize(v.normal.xyz) * outlineWidth;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.color = float4(_OutlineColor.xyz, outlineWidth);
	o.uv = v.uv;
	return o;
}

fixed4 frag( v2f i ) : COLOR
{
	#ifdef cutout
		float4 maintex = UNITY_SAMPLE_TEX2D(_MainTex, i.uv);
		clip(maintex.a - _Cutoff);
	#endif

	//alpha of the color is passed in as the width of our outline - if it's 0, then we discard it.
	clip(i.color.a == 0 ? -1 : 1);

	float3 indirectIntensity = ShadeSH9(float4(0,0,0,1));
	float3 col = i.color * (length(indirectIntensity) / 3);
	return float4(col, 1);
}
