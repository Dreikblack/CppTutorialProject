#pragma once
#include "Leadwerks.h"

using namespace UltraEngine;

const float CAMERA_PITCH = 54.736f;

class TopDownCamera : public Component {
protected:
	std::weak_ptr<Pivot> targetPivot;
	std::weak_ptr<Scene> sceneWeak;

	int borderMoveThickness = 5;
	float borderMove = 0.01f;

	int oldScrollPos = 0;

	float moveSpeed = 8.0f;
	float scrollSpeed = 0.2f;
	float minHeight = 4.0f;
	float maxHeight = 10.0f;
	float normalizeAngle(float angle) const;
public:

	TopDownCamera();
	~TopDownCamera() override;
	shared_ptr<Component> Copy() override;
	bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	bool init();
	void Update() override;
	void rotate(bool isLeft, float coeff = 1);
	void rotate(float angle);
	void zoom(int scrollData);
	void Start() override;
};