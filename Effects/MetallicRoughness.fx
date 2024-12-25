{
    "posteffect":
    {
        "subpasses":
        [
            {
                "samplers": ["METALLICROUGHNESS"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/MetallicRoughness.frag"
                    }
                }
            }
        ]
    }
}