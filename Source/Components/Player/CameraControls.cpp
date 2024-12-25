#pragma once
#include "UltraEngine.h"
#include "CameraControls.h"

using namespace UltraEngine;

CameraControls::CameraControls()
{
	name = "CameraControls";
}

void CameraControls::Update()
{
	auto entity = GetEntity();
	auto window = ActiveWindow();
	if (window == NULL) return;
	if (!freelookstarted)
	{
		freelookstarted = true;
		freelookrotation = entity->GetRotation(true);
		freelookmousepos = window->GetMouseAxis();
	}
	auto newmousepos = window->GetMouseAxis();
	lookchange.x = lookchange.x * mousesmoothing + (newmousepos.y - freelookmousepos.y) * 100.0f * mouselookspeed * (1.0f - mousesmoothing);
	lookchange.y = lookchange.y * mousesmoothing + (newmousepos.x - freelookmousepos.x) * 100.0f * mouselookspeed * (1.0f - mousesmoothing);
	if (Abs(lookchange.x) < 0.001f) lookchange.x = 0.0f;
	if (Abs(lookchange.y) < 0.001f) lookchange.y = 0.0f;
	if (lookchange.x != 0.0f or lookchange.y != 0.0f)
	{
		freelookrotation.x += lookchange.x;
		freelookrotation.y += lookchange.y;
		entity->SetRotation(freelookrotation, true);
	}
	freelookmousepos = newmousepos;
	float speed = movespeed / 60.0f;
	if (window->KeyDown(KEY_SHIFT))
	{
		speed *= 10.0f;
	}
	else if (window->KeyDown(KEY_CONTROL))
	{
		speed *= 0.25f;
	}
	if (window->KeyDown(KEY_E)) entity->Translate(0, speed, 0);
	if (window->KeyDown(KEY_Q)) entity->Translate(0, -speed, 0);
	if (window->KeyDown(KEY_D)) entity->Move(speed, 0, 0);
	if (window->KeyDown(KEY_A)) entity->Move(-speed, 0, 0);
	if (window->KeyDown(KEY_W)) entity->Move(0, 0, speed);
	if (window->KeyDown(KEY_S)) entity->Move(0, 0, -speed);
}

//This method will work with simple components
shared_ptr<Component> CameraControls::Copy()
{
	return std::make_shared<CameraControls>(*this);
}

bool CameraControls::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    if (properties["mousesmoothing"].is_number()) mousesmoothing = properties["mousesmoothing"];
    if (properties["mouselookspeed"].is_number()) mouselookspeed = properties["mouselookspeed"];
    if (properties["movespeed"].is_number()) movespeed = properties["movespeed"];
	return true;
}
	
bool CameraControls::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
	properties["mousesmoothing"] = mousesmoothing;
	properties["mouselookspeed"] = mouselookspeed;
	properties["movespeed"] = movespeed;
	return true;
}