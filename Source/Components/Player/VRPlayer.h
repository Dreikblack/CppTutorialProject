#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;

class VRPlayer : public Component
{
    shared_ptr<Hmd> hmd;
public:
	
	VRPlayer();

	virtual void Start();
	virtual shared_ptr<Component> Copy();
};