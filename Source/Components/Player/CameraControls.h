#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;

class CameraControls : public Component
{
    bool freelookstarted{ false };
	Vec3 freelookmousepos;
	Vec3 freelookrotation;
	Vec2 lookchange;
public:
	float mousesmoothing = 0.0f;
	float mouselookspeed = 1.0f;
	float movespeed = 4.0f;

	CameraControls();

	virtual void Update();
	virtual shared_ptr<Component> Copy();
	virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra);
	virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra);
};