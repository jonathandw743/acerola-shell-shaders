Shader "Unlit/ShellUnlitShader"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _ColorTex ("Color Texture", 2D) = "white" {}
        _ColorTexSize ("(x, y) Apparent size of the color texture", Vector) = (1.0, 1.0, 0.0)
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
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            float _HeightFactor;

            sampler2D _ColorTex;
            float2 _ColorTexSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float hash(uint n) {
				// integer hash copied from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}

            fixed4 frag (v2f i) : SV_Target
            {
                float2 luv = frac(i.uv) * 2 - 1;
                uint2 id = floor(i.uv);
                float2 idCentralised = id + float2(0.5, 0.5);
                uint seed = id.y * 100 + id.x + 10000;
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                float val = hash(seed);
                if (sqrt(luv.x * luv.x + luv.y * luv.y) > 1 - _HeightFactor / val) discard;
                //if (_Height > val) discard;

                fixed3 col = tex2D(_ColorTex, idCentralised / _ColorTexSize.xy) * _HeightFactor;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(col.x, col.y, col.z, 1.0);
            }
            ENDCG
        }
    }
}
