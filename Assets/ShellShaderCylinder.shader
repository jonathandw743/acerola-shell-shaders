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
            // a bit annoying to do this
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

            //bool RayConeIntersect(float3 ro, float3 rd, float3 cone_pos, float theta)
            //{
            //    float3 v = float3(0, -1, 0);

            //    // Calculate the vector from the ray origin to the cone tip.
            //    float3 co = ro - cone_pos;
    
            //    // Calculate the cosine of the half-angle of the cone.
            //    float cosTheta = cos(theta);

            //    // Calculate dot products to test for intersection.
            //    float a = dot(rd, v)*dot(rd,v) - cosTheta * cosTheta;
            //    float b = 2.0 * (dot(rd, v) * dot(co, v) - dot(rd, co) * cosTheta * cosTheta);
            //    float c = dot(co, v)*dot(co, v) - cosTheta * cosTheta * dot(co, co);

            //    // Calculate the discriminant to determine if there is an intersection.
            //    float determinant = b * b - 4.0 * a * c;


            //    // If the discriminant is non-negative, there is an intersection.
            //    if (determinant >= 0.0)
            //    {
            //        // Calculate the intersection points along the ray.
            //        float t1 = (-b - sqrt(determinant)) / (2.0 * a);
            //        float t2 = (-b + sqrt(determinant)) / (2.0 * a);

            //        float3 p1 = ro + t1 * rd;
            //        float3 p2 = ro + t2 * rd;

            //        if (p1.y > cone_pos.y && p2.y > cone_pos.y) return false;
            //        if (p1.y < 0.0 && p2.y < 0.0) return false;
            //        if (t1 < 0.0 && t2 < 0.0) return false;
        
            //        // Ensure that the intersection point is in front of the ray origin.
            //        return true;
            //    }

            //    return false; // No intersection.
            //}


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
                //val = 1.0;

                float3 coneTop = mul(unity_ObjectToWorld, float3(idCentralised.x, val * _AbsoluteMaxHeight, idCentralised.y));
                float theta = 0.15;
                
                float3 v = float3(0, -1, 0);

                // Calculate the vector from the ray origin to the cone tip.
                float3 co = ro - coneTop;
    
                // Calculate the cosine of the half-angle of the cone.
                float cosTheta = cos(theta);

                // Calculate dot products to test for intersection.
                float a = dot(rd, v)*dot(rd,v) - cosTheta * cosTheta;
                float b = 2.0 * (dot(rd, v) * dot(co, v) - dot(rd, co) * cosTheta * cosTheta);
                float c = dot(co, v)*dot(co, v) - cosTheta * cosTheta * dot(co, co);

                // Calculate the discriminant to determine if there is an intersection.
                float determinant = b * b - 4.0 * a * c;
                if (determinant < 0.0) discard;


                // If the discriminant is non-negative, there is an intersection.
                // Calculate the intersection points along the ray.
                //float t1 = (-b - sqrt(determinant)) / (2.0 * a);
                float t2 = (-b + sqrt(determinant)) / (2.0 * a);
                //float t2 = (-b + determinant) / (2.0 * a);

                //if (t1 < 0.0 && t2 < 0.0) discard;

                //float3 p1 = ro + t1 * rd;
                float3 p2 = ro + t2 * rd;

                //if (p1.y > coneTop.y && p2.y > coneTop.y) discard;
                //if (p1.y < 0.0 && p2.y < 0.0) discard;
                //float g = 3.0;
                //if (determinant < 0.0 || t2 < 0.0 || p2.y > coneTop.y || p2.y < 0.0) g = 2.0;
                //if (g == 1.0) discard;
                //if (t2 < 0.0) discard;
                if (p2.y > coneTop.y) discard;
                if (p2.y < 0.0) discard;


                float3 intersection = p2;
                fixed3 col = tex2D(_ColorTex, idCentralised / _ColorTexSize.xy) * intersection.y / _AbsoluteMaxHeight;
                //fixed3 col = fixed3(0, 1, 0) * intersection.y / _AbsoluteMaxHeight;
                //if (t2 < t1) {
                //    intersection = p2;
                //    col = fixed3(0.1 * intersection.y / _AbsoluteMaxHeight, 0, 0);
                //}


                //if ((luv.x * luv.x + luv.y * luv.y) > 1 - _HeightFactor / val) discard;
                //if (_HeightFactor > val) discard;

                //fixed3 col = fixed3(0, _HeightFactor, 0);
                // instead we can use the intersection point to calculate a smooth colour (almost) for free
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(col.x, col.y, col.z, 1.0);
            }
            ENDCG
        }
    }
}
