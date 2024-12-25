#pragma once
#include "UltraEngine.h"
#include "WayMover.h"
#include "../Logic/WayPoint.h"

using namespace UltraEngine;

WayMover::WayMover() {
	name = "WayMover";
	moveSpeed = 4.0f;
	isMoving = false;
	doDeleteAfterMovement = false;
}

shared_ptr<Component> WayMover::Copy() {
	return std::make_shared<WayMover>(*this);
}

bool WayMover::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	if (properties["moveSpeed"].is_number()) {
		moveSpeed = properties["moveSpeed"];
	}
	if (properties["moveSpeed"].is_boolean()) {
		isMoving = properties["isMoving"];
	}
	if (properties["doDeleteAfterMovement"].is_boolean()) {
		doDeleteAfterMovement = properties["doDeleteAfterMovement"];
	}
	if (properties["nextPoint"].is_string()) {
		std::string id = properties["nextPoint"];
		nextPoint = scene->GetEntity(id);
	}
	sceneWeak = scene;
	return Component::Load(properties, binstream, scene, flags, extra);
}

bool WayMover::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	properties["moveSpeed"] = moveSpeed;
	properties["isMoving"] = isMoving;
	properties["doDeleteAfterMovement"] = doDeleteAfterMovement;
	if (nextPoint.lock()) {
		properties["nextPoint"] = nextPoint.lock()->GetUuid();
	}
	return Component::Save(properties, binstream, scene, flags, extra);
}

std::any WayMover::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args) {
	//start moving by triggering by another component
	if (name == "DoMove") {
		isMoving = true;
	}
	return false;
}

void WayMover::Update() {
	if (!isMoving) {
		return;
	}
	auto entity = GetEntity();
	auto wayPoint = nextPoint.lock();
	if (!entity || !wayPoint) {
		return;
	}
	//60 HZ game loop, change to own value if different to keep same final speed
	float speed = moveSpeed / 60.0f;
	auto targetPosition = wayPoint->GetPosition(true);

	//moving to point with same speed directly to point no matter which axis
	auto pos = entity->GetPosition(true);
	float distanceX = abs(targetPosition.x - pos.x);
	float distanceY = abs(targetPosition.y - pos.y);
	float distanceZ = abs(targetPosition.z - pos.z);
	float biggestDelta = distanceZ;
	if (distanceX > distanceY && distanceX > distanceZ) {
		biggestDelta = distanceX;
	}
	else if (distanceY > distanceX && distanceY > distanceZ) {
		biggestDelta = distanceY;
	}

	float moveX = MoveTowards(pos.x, targetPosition.x, speed * (distanceX / biggestDelta));
	float moveY = MoveTowards(pos.y, targetPosition.y, speed * (distanceY / biggestDelta));
	float moveZ = MoveTowards(pos.z, targetPosition.z, speed * (distanceZ / biggestDelta));

	entity->SetPosition(moveX, moveY, moveZ);
	if (entity->GetPosition(true) == targetPosition) {
		moveEnd();
	}

}

void WayMover::moveEnd() {
	auto wayPoint = nextPoint.lock();
	bool doStay = false;
	if (wayPoint) {
		doStay = wayPoint->GetComponent<WayPoint>()->doStayOnPoint;
		wayPoint = wayPoint->GetComponent<WayPoint>()->getNextPoint();
		nextPoint = wayPoint;
	}
	if (doStay || !wayPoint) {
		isMoving = false;
		FireOutputs("EndMove");
		//deleting entity if need to, after reaching final way point
		if (!doStay && !wayPoint && doDeleteAfterMovement && !sceneWeak.expired()) {
			auto scene = sceneWeak.lock();
			scene->RemoveEntity(GetEntity());
		}
	}
}
