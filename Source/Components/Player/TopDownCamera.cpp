#include "Leadwerks.h"
#include "TopDownCamera.h"


Vec3 getCirleCenter(Vec3 cameraPosition, Vec3 cameraRotaion) {
	float distance = cameraPosition.y * Tan(CAMERA_PITCH);
	distance = sqrt(distance * distance / 2);
	Vec3 center = cameraPosition;
	center.x = cameraPosition.x + distance * Cos(cameraRotaion.y);
	center.z = cameraPosition.z + distance * Sin(cameraRotaion.y);
	return center;
}

TopDownCamera::TopDownCamera() {
	name = "TopDownCamera";
}

shared_ptr<Component> TopDownCamera::Copy() {
	return std::make_shared<TopDownCamera>(*this);
}

TopDownCamera::~TopDownCamera() = default;

void TopDownCamera::Start() {
	auto entity = GetEntity();
	entity->AddTag("Camera");
	init();
}

bool TopDownCamera::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	Component::Load(properties, binstream, scene, flags, extra);
	if (properties["minHeight"].is_number()) maxHeight = properties["minHeight"];
	if (properties["maxHeight"].is_number()) maxHeight = properties["maxHeight"];
	sceneWeak = scene;
	return true;
}

bool TopDownCamera::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	Component::Save(properties, binstream, scene, flags, extra);
	properties["minHeight"] = minHeight;
	properties["maxHeight"] = maxHeight;
	return true;
}


bool TopDownCamera::init() {
	auto gameCamera = GetEntity()->As<Camera>();
	if (gameCamera == nullptr) {
		return false;
	}
	auto window = ActiveWindow();
	if (window) {
		auto framebuffer = window->GetFramebuffer();
		auto sz = framebuffer->GetSize();
		borderMoveThickness = (float)sz.width * borderMove;
	}
	
	if (gameCamera && !targetPivot.lock()) {
		gameCamera->Listen();//for positional sound 
		gameCamera->SetSweptCollision(true);//for removing pop up effect after quick move/turn
		gameCamera->SetRotation(CAMERA_PITCH, gameCamera->GetRotation(true).y, gameCamera->GetRotation(true).z);
		auto targetPivotShared = CreatePivot(gameCamera->GetWorld());
		targetPivotShared->SetPickMode(PICK_NONE);	
		sceneWeak.lock()->AddEntity(targetPivotShared);
		targetPivot = targetPivotShared;
	}
	//setting position and rotation here in case of game load
	gameCamera->SetParent(nullptr);
	auto targetPivotShared = targetPivot.lock();
	auto targetPosition = getCirleCenter(gameCamera->GetPosition(true), gameCamera->GetRotation(true));
	targetPosition.y = 0;
	targetPivotShared->SetPosition(targetPosition);
	targetPivotShared->SetRotation(0, gameCamera->GetRotation(true).y, gameCamera->GetRotation(true).z);
	gameCamera->SetParent(targetPivotShared);
	return true;
}

void TopDownCamera::Update() {
	auto entity = GetEntity();
	auto window = ActiveWindow();
	if (window == nullptr || entity == nullptr || !entity->GetWorld()) {
		return;
	}
	float speed = moveSpeed / 60.0f;
	auto mousePosition = window->GetMousePosition();
	auto pivot = targetPivot.lock();

	bool moveLeft = window->KeyDown(KEY_A);
	bool moveRight = window->KeyDown(KEY_D);
	bool moveUpward = window->KeyDown(KEY_W);
	bool moveDown = window->KeyDown(KEY_S);

	auto clientSize = window->ClientSize();

	if (mousePosition.y > 0 && mousePosition.y < borderMoveThickness) moveUpward = true;
	if (mousePosition.y < clientSize.y && mousePosition.y >(clientSize.y - borderMoveThickness)) moveDown = true;
	if (mousePosition.x > 0 && mousePosition.x < borderMoveThickness) moveLeft = true;
	if (mousePosition.x < clientSize.x && mousePosition.x >(clientSize.x - borderMoveThickness)) moveRight = true;

	if (moveLeft) pivot->Move(-speed * 2, 0, 0);
	if (moveRight) pivot->Move(speed * 2, 0, 0);
	if (moveUpward) pivot->Move(0, 0, speed * 2);
	if (moveDown) pivot->Move(0, 0, -speed * 2);
	if (window->KeyDown(KEY_Q)) rotate(true);
	if (window->KeyDown(KEY_E)) rotate(false);

	int zoomDelta = oldScrollPos - mousePosition.z;
	zoom(-zoomDelta);
	oldScrollPos = mousePosition.z;
}


void TopDownCamera::rotate(bool isLeft, float coeff) {
	auto entity = GetEntity();
	float heightCoeff = entity->GetPosition(true).height / minHeight;
	float angleStep = coeff * 360.0f / (60.0f * heightCoeff * 2.0f);//40 per 1 sec
	rotate(isLeft ? angleStep : -angleStep);
}

void TopDownCamera::rotate(float angle) {
	auto pivot = targetPivot.lock();
	auto rotation = pivot->GetRotation(true);
	rotation.y = normalizeAngle(rotation.y + angle);
	pivot->SetRotation(rotation);
}

float TopDownCamera::normalizeAngle(float angle) const {
	const float twoPi = 360.0f;
	while (angle > twoPi) {
		angle -= twoPi;
	}

	while (angle < 0.0f) {
		angle += twoPi;
	}
	return angle;
}

void TopDownCamera::zoom(int scrollData) {
	float zoomDelta = float(scrollData) * scrollSpeed;
	auto window = ActiveWindow();
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (!window || !entity || !world) return;
	auto cameraPosition = entity->GetPosition(true);
	float newCameraHeight = cameraPosition.y + zoomDelta;
	if (cameraPosition.y > maxHeight) {
		newCameraHeight = maxHeight;
	} else if (cameraPosition.y < minHeight) {
		newCameraHeight = minHeight;
	}
	auto cameraTargetBottomPick = cameraPosition;
	cameraTargetBottomPick.y = minHeight;
	cameraPosition.y = maxHeight;
	auto cameraPick = world->Pick(cameraPosition, cameraTargetBottomPick, 0, true);
	if (cameraPick.success && newCameraHeight < cameraPick.position.y + 2) {
		newCameraHeight = cameraPick.position.y + 2;
	}
	if ((newCameraHeight <= maxHeight)
		&& newCameraHeight >= minHeight) {
		cameraPosition.y = newCameraHeight;
		auto pick = GetEntity()->As<Camera>()->Pick(window->GetFramebuffer(), Round((float)window->ClientSize().x / 2.0f), Round((float)window->ClientSize().y / 2.0f), 0, true);
		Vec3 targetPosition;
		if (pick.success) {
			targetPosition = pick.position;
			if (targetPosition.y < 0 && minHeight > 0) {
				targetPosition.y = 0;
			}
		}
		else {
			targetPosition = getCirleCenter(cameraPosition, GetEntity()->GetRotation(true));
		}
		targetPivot.lock()->SetPosition(targetPosition, true);
		entity->SetPosition(cameraPosition, true);
	}
}