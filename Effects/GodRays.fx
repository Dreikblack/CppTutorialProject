{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.25, 0.25],
                "format": 37
            }
        ],
        "subpasses":
        [
            {    
                "samplers": ["PREVPASS"],
                "colorattachments": [0],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/GodRays.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", 0],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/GodRaysResolve.frag"
                    }
                }
            }
        ]
    }
}