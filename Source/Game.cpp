#include "UltraEngine.h"
#include "Game.h"
#include "CustomEvents.h"

Game::Game() = default;

std::shared_ptr<Game> Game::create(shared_ptr<Framebuffer> framebuffer, WString mapPath) {
	struct Struct : public Game {};
	auto instance = std::make_shared<Struct>();
	instance->init(framebuffer, mapPath);
	return instance;
}

bool Game::GameMenuButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	if (KEY_ESCAPE == ev.data && extra) {
		auto game = extra->As<Game>();
		bool isHidden = game->menuPanel->GetHidden();
		game->menuPanel->SetHidden(!isHidden);
		if (game->fpsPlayer) {
			//we can get a game window anywhere, but take in mind that it will return nullptr, if window is not active ;)
			auto window = ActiveWindow();
			//checking just in case if we actually got a window
			if (window) {
				//hiding cursor when hiding a menu and vice versa
				window->SetCursor(isHidden ? CURSOR_DEFAULT : CURSOR_NONE);
			}
			game->fpsPlayer->doResetMousePosition = !isHidden;
		}
		
		//If the callback function returns false no more callbacks will be executed and no event will be added to the event queue.
		//to avoid double call
		return false;
	}
	return true;
}

static bool MainMenuButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	EmitEvent(EVENT_MAIN_MENU);
	return true;
}

static bool ExitButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	exit(0);
	return true;
}

void Game::init(shared_ptr<Framebuffer> framebuffer, WString mapPath) {
	world = CreateWorld();
	scene = LoadMap(world, mapPath);
	for (auto const& entity : scene->entities) {
		auto foundPlayer = entity->GetComponent<FPSPlayer>();
		if (foundPlayer) {
			fpsPlayer = foundPlayer;
			break;
		}
	}
	auto font = LoadFont("Fonts/arial.ttf");
	//Create user interface for game menu
	auto frameSize = framebuffer->GetSize();
	ui = CreateInterface(world, font, frameSize);
	ui->SetRenderLayers(2);
	ui->root->SetColor(0.0f, 0.0f, 0.0f, 0.0f);
	uiCamera = CreateCamera(world, PROJECTION_ORTHOGRAPHIC);
	uiCamera->SetPosition(float(frameSize.x) * 0.5f, float(frameSize.y) * 0.5f, 0);
	uiCamera->SetRenderLayers(2);
	uiCamera->SetClearMode(CLEAR_DEPTH);
	//widgets are stays without extra shared pointers because parent widet, ui->root in this case, keep them
	//to remove widget you should do widget->SetParent(nullptr)
	menuPanel = CreatePanel(frameSize.width / 2 - 150, frameSize.height / 2 - 300 / 2, 300, 250, ui->root);
	auto menuButton = CreateButton("Main menu", 50, 50, 200, 50, menuPanel);
	ListenEvent(EVENT_WIDGETACTION, menuButton, MainMenuButtonCallback);
	auto exitButton = CreateButton("Exit", 50, 150, 200, 50, menuPanel);
	ListenEvent(EVENT_WIDGETACTION, exitButton, ExitButtonCallback, nullptr);
	//we don't need game menu on screen while playing
	menuPanel->SetHidden(true);
	//and we will need it once hitting Esc button
	ListenEvent(EVENT_KEYUP, nullptr, GameMenuButtonCallback, Self());
	//take in mind that extra param will be kept as shared_ptr in callback ^
}