{
    "posteffect":
    {
        "subpasses":
        [
            {    
                "samplers": ["PREVPASS"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/Grayscale.frag"
                    }
                }
            }
        ]
    }
}