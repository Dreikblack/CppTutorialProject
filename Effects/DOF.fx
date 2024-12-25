{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.5, 0.5],
                "format": 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            }
        ],
        "subpasses":
        [
            {
                "colorattachments": [0],
                "samplers": [ "PREVPASS" ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BlurX.frag"
                    }
                }
            },
            {
                "colorattachments": [1],
                "samplers": [ 0 ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BlurY.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", "DEPTH", 1],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/DOFResolve.frag"
                    }
                }
            }                      
        ]
    }
}