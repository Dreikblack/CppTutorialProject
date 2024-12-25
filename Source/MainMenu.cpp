#include "UltraEngine.h"
#include "MainMenu.h"
#include "CustomEvents.h"

//default empty constructor
MainMenu::MainMenu() = default;

//it's better to always use shared_ptr and it's a static dedicated method to make one
std::shared_ptr<MainMenu> MainMenu::create(shared_ptr<Framebuffer> framebuffer) {
	//struct are kinda mini classes, using it in create methods for proper accesses
	struct Struct : public MainMenu {};
	auto instance = std::make_shared<Struct>();
	instance->init(framebuffer);
	return instance;
}

static bool NewGameButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	EmitEvent(EVENT_GAME_START, nullptr, 0, 0, 0, 0, 0, nullptr, "start.ultra");
	return true;
}

static bool ExitButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	//to close application
	exit(0);
	return true;
}

void MainMenu::init(shared_ptr<Framebuffer> framebuffer) {
	world = CreateWorld();
	scene = LoadMap(world, "Maps/menu.ultra");
	//Load a font
	auto font = LoadFont("Fonts/arial.ttf");
	//Create user interface
	auto frameSize = framebuffer->GetSize();
	ui = CreateInterface(world, font, frameSize);
	ui->SetRenderLayers(2);
	//to make backgrount transparent
	ui->root->SetColor(0.0f, 0.0f, 0.0f, 0.0f);
	//Create camera for GUI
	uiCamera = CreateCamera(world, PROJECTION_ORTHOGRAPHIC);
	uiCamera->SetPosition(float(frameSize.x) * 0.5f, float(frameSize.y) * 0.5f, 0);
	uiCamera->SetRenderLayers(2);
	//for correct rendering above 3D scene
	uiCamera->SetClearMode(CLEAR_DEPTH);
	//Menu buttons
	auto newGameButton = CreateButton("New game", frameSize.width / 2 - 100, 125, 200, 50, ui->root);
	ListenEvent(EVENT_WIDGETACTION, newGameButton, NewGameButtonCallback);
	auto exitButton = CreateButton("Exit", frameSize.width / 2 - 100, 200, 200, 50, ui->root);
	ListenEvent(EVENT_WIDGETACTION, exitButton, ExitButtonCallback);
}