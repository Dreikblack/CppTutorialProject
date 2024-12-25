{
    "posteffect":
    {
        "subpasses":
        [
            {
                "samplers": ["ALBEDO"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BaseColor.frag"
                    }
                }
            }
        ]
    }
}