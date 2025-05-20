#pragma once
#include "Leadwerks.h"
#include "WayPoint.h"

using namespace Leadwerks;

WayPoint::WayPoint() {
	//name should always match class name for correct component work
	name = "WayPoint";
	doStayOnPoint = false;
}

shared_ptr<Component> WayPoint::Copy() {
	return std::make_shared<WayPoint>(*this);
}

void WayPoint::Start() {
	//empty for this case
}

bool WayPoint::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	//internally entity saves in the Editor as String unique id
	//can be empty if this way point is final
	if (properties["nextPoint"].is_string()) {
		std::string id = properties["nextPoint"];
		nextPoint = scene->GetEntity(id);
		if (properties["doStayOnPoint"].is_boolean()) {
			doStayOnPoint = properties["doStayOnPoint"];
		}
	}
	return true;
}

bool WayPoint::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	if (nextPoint.lock()) {
		properties["nextPoint"] = nextPoint.lock()->GetUuid();
		properties["doStayOnPoint"] = doStayOnPoint;
	}
	return true;
}

shared_ptr<Entity> WayPoint::getNextPoint() const {
	return nextPoint.lock();
}