{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [1.0, 1.0],
                "format": 97
            }
        ],
        "subpasses":
        [
            {
                "colorattachments": [0],
                "samplers": [1],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/copy_prev_frame.frag"
                    }
                }
            },  
            {
                "colorattachments": [1],
                "samplers": ["DEPTH", 0],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/VolumetricLighting.frag"
                    }
                }
            },  
            {
                "colorattachments": [2],
                "samplers": [ 1 ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BlurX_Vol.frag"
                    }
                }
            },
            {
                "colorattachments": [3],
                "samplers": [ 2 ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BlurY_Vol.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", 3, "DEPTH"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/VolumetricLightingResolve.frag"
                    }
                }
            }      
        ]
    }
}