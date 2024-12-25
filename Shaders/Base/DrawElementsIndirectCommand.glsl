struct DrawElementsIndirectCommand
{
    uint count;
    uint instanceCount;
    uint firstIndex;
    int baseVertex;
    uint baseInstance;
    uint materialID;
    uint primitivesIndex;
    uint primitivesCount;
    float meshtexturescale;
    uint meshflags;
    uint alignment;
};
