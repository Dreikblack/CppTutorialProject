#pragma once
#include "Leadwerks.h"

using namespace Leadwerks;

class VRPlayer : public Component
{
    shared_ptr<Hmd> hmd;
public:
	
	VRPlayer();

	virtual void Start();
	virtual shared_ptr<Component> Copy();
};