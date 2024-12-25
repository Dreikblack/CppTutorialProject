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
            },
            {
                "size": [0.125, 0.125] ,
                "format" : 97
            },
            {
                "size": [0.0625, 0.0625] ,
                "format" : 97
            },
            {
                "size": [0.03125, 0.03125] ,
                "format" : 97
            },
             {
                "size": [0.015625, 0.015625] ,
                "format" : 97
            },
            {
                "size": [0.03125, 0.03125] ,
                "format" : 97
            },
            {
                "size": [0.0625, 0.0625] ,
                "format" : 97
            },
            {
                "size": [0.125, 0.125] ,
                "format" : 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [0.5, 0.5],
                "format": 97
            }
        ],
        "subpasses":
        [
            {
                "colorattachments": [0],
                "samplers": [ "PREVPASS", "DEPTH" ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomPrefilter.frag"
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
                        "fragment": "Shaders/PostEffects/BloomDownSample.frag"
                    }
                }
            },
            {
                "colorattachments": [2] ,
                "samplers" : [ 1 ],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomDownSample.frag"
                    }
                }
            },
            {
                "colorattachments": [3],
                "samplers" : [2],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomDownSample.frag"
                    }
                }
            },
            {
                "colorattachments": [4],
                "samplers" : [3],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomDownSample.frag"
                    }
                }
            },
             {
                "colorattachments": [5],
                "samplers" : [4],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomDownSample.frag"
                    }
                }
            },
            {
                "colorattachments": [6],
                "samplers" : [4,5],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomUpscaleCombine.frag"
                    }
                }
            },
            {
                "colorattachments": [7],
                "samplers" : [4,6],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomUpscaleCombine.frag"
                    }
                }
            },
            {
                "colorattachments": [8],
                "samplers" : [3,7],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomUpscaleCombine.frag"
                    }
                }
            },
            {
                "colorattachments": [9],
                "samplers" : [2,8],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomUpscaleCombine.frag"
                    }
                }
            },
            {
                "colorattachments": [10],
                "samplers" : [1,9],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomUpscaleCombine.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", "DEPTH", 10],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomFinalPass.frag"
                    }
                }
            }                      
        ]
    }
}