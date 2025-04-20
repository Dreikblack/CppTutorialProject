{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.5, 0.5],
                "format": 97
            }
        ],
        "subpasses":
        [
            {
                "colorattachments": [0],
                "samplers": ["DEPTH", "NORMAL", "PREVPASS"],
                "shader":
                {
                    "float32":
                    {                    
                        "fragment": "Shaders/PostEffects/SSAO.frag"
                    }
                }
            },
            {
                "samplers" : ["PREVPASS", 0],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/SSAOResolve.frag"
                    }
                }
            }
        ]
    }
}