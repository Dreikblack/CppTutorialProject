{
    "posteffect":
    {
        "subpasses":
        [
            {
                "samplers": ["NORMAL", "DEPTH"] ,
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/WorldNormals.frag"
                    }
                }
            }
        ]
    }
}