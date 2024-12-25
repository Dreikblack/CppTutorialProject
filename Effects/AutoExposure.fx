{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.1, 0.1],
                "format" : 97
            }
        ],
        "subpasses":
        [
            {
                "samplers": ["AVGLUMINANCE"],
                "colorattachments": [0],
                "shader":
                {
                    "float32":
                    {                    
                        "fragment": "Shaders/PostEffects/ExposureControl.frag"
                    }
                },
                "blend": [770, 771]
            },
            {
                "samplers": ["PREVPASS", 0],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/AutoExposure.frag"
                    }
                }
            }
        ]
    }
}