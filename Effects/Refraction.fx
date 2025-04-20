{
    "posteffect":
    {
        "premultiplyAlpha": true,
        "subpasses":
        [
            {
                "samplers": ["PREVPASS", "DEPTH", "TRANSPARENCY_NORMAL", "TRANSPARENCY", "METALLICROUGHNESS", "ZPOSITION"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/Refraction.frag"
                    }
                }
            }
        ]
    }
}