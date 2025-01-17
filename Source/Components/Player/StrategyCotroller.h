#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;


class StrategyCotroller : public Component {
protected:
	vector<std::weak_ptr<Entity>> selectedUnits;
	bool isControlDown = false;
	int playerTeam = 1;
	std::weak_ptr<Camera> cameraWeak;
	shared_ptr<Sprite> unitSelectionBox;
	shared_ptr<Brush> unitSelectionBox1;
	shared_ptr<Brush> unitSelectionBox2;
	iVec2 unitSelectionBoxPoint1;
	float selectHeight = 4;
	bool isMouseLeftDown = false;
	void updateUnitSelectionBox();
	bool selectUnitsByBox(shared_ptr<Camera> camera, shared_ptr<Framebuffer> framebuffer, iVec2 unitSelectionBoxPoint2);
	void deselectAllUnits();
public:
	StrategyCotroller();
	~StrategyCotroller() override;
	shared_ptr<Component> Copy() override;
	bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	void Update() override;
	void Start() override;
	bool ProcessEvent(const Event& e) override;
};