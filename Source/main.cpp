#include "Leadwerks.h"
#include "ComponentSystem.h"
#include "MainMenu.h"
#include "CustomEvents.h"
#include "Game.h"

using namespace Leadwerks;

shared_ptr<Window> window;
shared_ptr<Framebuffer> framebuffer;
//loading screen vars
shared_ptr<World> loadingWorld;
shared_ptr<Camera> loadingCamera;
shared_ptr<Sprite> loadingText;
shared_ptr<Sprite> loadingBackground;

//for using in main loop
shared_ptr<World> currentWorld;
shared_ptr<Interface> currentUi;

shared_ptr<MainMenu> menu;
shared_ptr<Game> game;


static bool StartGameEventCallback(const Event& e, shared_ptr<Object> extra) {
	//destroying a main menu
	menu.reset();
	//to show loading screen
	loadingWorld->Render(framebuffer);
	game = Game::create(framebuffer, e.text);
	//switching current render and update targets for loop
	currentWorld = game->world;
	currentUi = game->ui;
	//to avoid crash when engine will try to proccess prev ui, catching in main loop
	throw std::invalid_argument("Game");
	return true;
}

bool MainMenuEventCallback(const Event& e, shared_ptr<Object> extra) {
	//destroying a game instance if one existed
	game.reset();
	loadingWorld->Render(framebuffer);
	menu = MainMenu::create(framebuffer);
	//switching current render and update targets for loop
	currentWorld = menu->world;
	currentUi = menu->ui;
	throw std::invalid_argument("Main menu");
	return true;
}

int main(int argc, const char* argv[]) {
	//Need it to make component from map's entites start working
	RegisterComponents();
	//Computer screens
	auto displays = GetDisplays();
	window = CreateWindow("Ultra Engine Game", 0, 0, 1080, 720, displays[0], WINDOW_CENTER | WINDOW_TITLEBAR);
	framebuffer = CreateFramebuffer(window);
	//need a dedicated world to be able render and to stop renedering loading screen wheen needed
	loadingWorld = CreateWorld();
	float centerX = float(framebuffer->GetSize().x) * 0.5f;
	float centerY = float(framebuffer->GetSize().y) * 0.5f;
	float labelHeight = float(framebuffer->GetSize().y) * 0.2f;
	loadingBackground = CreateSprite(loadingWorld, framebuffer->size.width, framebuffer->size.height);
	loadingBackground->SetColor(0.2f, 0.2f, 0.2f);
	loadingBackground->SetRenderLayers(2);
	loadingBackground->SetPosition(centerX, centerY);
	auto font = LoadFont("Fonts/arial.ttf");
	loadingText = CreateSprite(loadingWorld, font, "LOADING", labelHeight, TEXT_CENTER | TEXT_MIDDLE);
	loadingText->SetPosition(centerX, centerY + labelHeight * 0.5f);
	//0 layer - no render, 1 - default render, we will use 2 for UI and sprites
	loadingText->SetRenderLayers(2);

	//Creating camera for sprites, which needs to be orthographic (2D) for UI and sprites if they used as UI
	loadingCamera = CreateCamera(loadingWorld, PROJECTION_ORTHOGRAPHIC);
	loadingCamera->SetPosition(centerX, centerY, 0);
	//camera render layer should match with stuff that you want to be visible for this camera. RenderLayers is a bit mask, so you can combine few layers, but probably you don't need it in most cases
	loadingCamera->SetRenderLayers(2);

	//to show Loading screen before Main Menu
	loadingWorld->Render(framebuffer);

	//ListenEvent are needed to do something in callback function when specific even from specfic source (or not, if 2nd param is nullptr) emitted
	ListenEvent(EVENT_GAME_START, nullptr, StartGameEventCallback);
	ListenEvent(EVENT_MAIN_MENU, nullptr, MainMenuEventCallback);
	
	auto cl = ParseCommandLine(argc, argv);
	WString mapName = "";
	if (cl["map"].is_string()) {
		mapName = std::string(cl["map"]);
	}
	try {
		if (mapName.empty()) {
			EmitEvent(EVENT_MAIN_MENU);
		} else {
			EmitEvent(EVENT_GAME_START, nullptr, 0, 0, 0, 0, 0, nullptr, mapName);
		}
	} catch (const std::invalid_argument& e) {
		//do nothing
	}

	//simple minimum game loop
	while (window->Closed() == false) {
		//getting all events from queue - input, UI etc. 
		while (PeekEvent()) {
			const Event ev = WaitEvent();
			try {
				if (currentUi) {
					currentUi->ProcessEvent(ev);
				}
			} catch (const std::invalid_argument& e) {
				//Stop processing old ui
			}
		}
		if (currentWorld) {
			//Update game logic (positions, components etc.). By default 60 HZ and not depends on framerate if you have 60+ FPS
			currentWorld->Update();
			//2nd param is VSync (true by default), 3rd is fps limit. Can by changed dynamically.
			currentWorld->Render(framebuffer);
		}
	}
	//if get here by closing window application will ends/closes
	return 0;
}