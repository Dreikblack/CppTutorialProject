void PackSelectionState(inout vec4 c, in bool selected)
{
    //c.r = max(c.r, 0.0f);
    //if (selected) c.r = -(c.r + 1.0f);
}

void UnpackSelectionState(inout vec4 c, out bool selected)
{
    selected = false;
    return;
    //selected = c.r < 0.0f;
    //c.r = abs(c.r);

    if (c.r < -0.5f)
    {
        c.r = -c.r - 1.0f;
        selected = true;
    }
    else
    {
        selected = false;
    }
}
