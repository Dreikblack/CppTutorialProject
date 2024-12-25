{
    "posteffect":
    {
        "subpasses":
        [
            {
                "samplers": ["DEPTH", "NORMAL", "PREVPASS"],
                "shader":
                {
                    "float32":
                    {                    
                        "fragment": "Shaders/PostEffects/SSAO.frag"
                    }
                }
            }           
        ]
    }
}