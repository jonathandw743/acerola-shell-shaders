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
                float3 worldPos: TEXCOORD2;
            };

            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            float _HeightFactor;
            float _AbsoluteMaxHeight;

            float3 _MainCameraPos;

            sampler2D _ColorTex;
            float2 _ColorTexSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                //UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

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
                float3 ro = _MainCameraPos.xyz;
                float3 rd = normalize(i.worldPos - ro);

                float3 triNormal = normalize(float3(-rd.x, 0, -rd.z));

                float2 luv = frac(i.uv) * 2 - 1;
                uint2 id = floor(i.uv);
                float2 idCentralised = id + float2(0.5, 0.5);
                uint seed = id.y * 100 + id.x + 10000;
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                float val = hash(seed);
                
                float3 triTop = mul(unity_ObjectToWorld, float4(idCentralised.x, val * _AbsoluteMaxHeight, idCentralised.y, 1.0));
                float t = dot(triNormal, (triTop - ro)) / dot(triNormal, rd);
                float3 intersectionPoint = ro + t * rd;

                if (intersectionPoint.y < 0) discard;

                float3 intersectionToTriTop = normalize(triTop - intersectionPoint);

                // doing a dot product with an axis vector is dumb
                if (dot(intersectionToTriTop, float3(0, 1, 0)) < dot(normalize(triTop - float3(id.x, 0, id.y)), float3(0, 1, 0))) discard;



                //if ((luv.x * luv.x + luv.y * luv.y) > 1 - _HeightFactor / val) discard;
                //if (_HeightFactor > val) discard;

                //fixed3 col = fixed3(0, _HeightFactor, 0);
                // instead we can use the intersection point to calculate a smooth colour (almost) for free
                fixed3 col = tex2D(_ColorTex, idCentralised / _ColorTexSize.xy) * intersectionPoint.y / _AbsoluteMaxHeight;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(col.x, col.y, col.z, 1.0);
            }
            ENDCG
        }
    }
}
