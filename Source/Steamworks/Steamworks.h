#pragma once
#include "UltraEngine.h"
#include "public/steam/steam_api.h"
#ifdef _WIN32
	#pragma comment(lib, "Source/Steamworks/steam_api64.lib")
	#undef GetUserName
	#undef SendMessage
	#undef GetMessage
#endif

namespace Steamworks
{
	const enum
	{
		STEAMWORKS_TIMEOUT = 10000,
		CHANNEL_VOICE = 1004
	};

	extern bool Initialize();
	extern void Shutdown();
	extern void Update();

	//-------------------------------------------------------------------------------
	// Steam hooks
	//-------------------------------------------------------------------------------

	struct SteamHooks
	{
		bool finished{ false };

		bool Wait(uint64_t timeout = STEAMWORKS_TIMEOUT)
		{
			const int pause = 50;
			uint64_t elapsed = 0;
			while (true)
			{
				Update();
				if (finished) break;
				Sleep(pause);
				elapsed += pause;
				if (timeout != 0 and elapsed > timeout) return false;
			}
			return true;
		}

		LeaderboardFindResult_t m_LeaderboardFindResult_t = {};
		CCallResult <SteamHooks, LeaderboardFindResult_t> LeaderboardFindResult_t_CCallResult;

		void FindOrCreateLeaderboardResultHook(LeaderboardFindResult_t* result, bool b)
		{
			this->m_LeaderboardFindResult_t = *result;
			finished = true;
		}

		LeaderboardScoresDownloaded_t m_LeaderboardScoresDownloaded_t;
		CCallResult <SteamHooks, LeaderboardScoresDownloaded_t > LeaderboardScoresDownloaded_t_CCallResult;

		void LeaderboardScoresDownloadedHook(LeaderboardScoresDownloaded_t* result, bool b)
		{
			this->m_LeaderboardScoresDownloaded_t = *result;
			finished = true;
		}

		LobbyCreated_t m_LobbyCreated_t;
		CCallResult <SteamHooks, LobbyCreated_t> LobbyCreated_t_CCallResult;

		void CreateLobbyHook(LobbyCreated_t* result, bool b)
		{
			this->m_LobbyCreated_t = *result;
			finished = true;
		}

		LobbyEnter_t m_LobbyEnter_t;
		CCallResult <SteamHooks, LobbyEnter_t> LobbyEnter_t_CCallResult;

		void EnterLobbyHook(LobbyEnter_t* result, bool b)
		{
			this->m_LobbyEnter_t = *result;
			finished = true;
		}

		LobbyMatchList_t m_LobbyMatchList_t;
		CCallResult <SteamHooks, LobbyMatchList_t> LobbyMatchList_t_CCallResult;

		void LobbyMatchListHook(LobbyMatchList_t* result, bool b)
		{
			this->m_LobbyMatchList_t = *result;
			finished = true;
		}
	};

	const UltraEngine::EventId EVENT_LOBBYDATACHANGED = UltraEngine::EventId(91400);
	const UltraEngine::EventId EVENT_LOBBYUSERJOIN = UltraEngine::EventId(91401);
	const UltraEngine::EventId EVENT_LOBBYUSERLEAVE = UltraEngine::EventId(91402);
	const UltraEngine::EventId EVENT_LOBBYUSERDISCONNECT = UltraEngine::EventId(91403);
	const UltraEngine::EventId EVENT_LOBBYINVITEACCEPTED = UltraEngine::EventId(91404);
	//const UltraEngine::EventId EVENT_LOBBYUSERKICKED = UltraEngine::EventId(91403);
	//const UltraEngine::EventId EVENT_LOBBYUSERBANNED = UltraEngine::EventId(91404);
	const UltraEngine::EventId EVENT_STEAMOVERLAY = UltraEngine::EventId(91408);

	struct LobbyEventInfo : public UltraEngine::Object
	{
		uint64_t lobbyid { 0ull };
		uint64_t userid { 0ull };
	};

	//-------------------------------------------------------------------------------
	// User
	//-------------------------------------------------------------------------------

	extern uint64_t GetUserId();
	extern UltraEngine::WString GetUserName(const uint64_t userid);
	extern shared_ptr<UltraEngine::Pixmap> GetUserAvatar(const uint64_t userid);

	//-------------------------------------------------------------------------------
	// Apps
	//-------------------------------------------------------------------------------

	extern uint64_t GetAppId();
	extern int GetBuildId();
	extern bool AppSubscribed(uint64_t appid);
	extern bool AppInstalled(uint64_t appid);
	extern bool DlcInstalled(uint64_t appid);

	//-------------------------------------------------------------------------------
	// Statistics and achievements
	//-------------------------------------------------------------------------------

	extern bool SetStat(const UltraEngine::WString& name, const int i);
	extern int GetStat(const UltraEngine::WString& name);
	extern bool AddStat(const UltraEngine::WString& name, const int amount = 1);
	extern bool UnlockAchievement(const UltraEngine::WString& name);
	
	//-------------------------------------------------------------------------------
	// Leaderboards
	//-------------------------------------------------------------------------------

	enum LeaderboardDataRequest
	{
		LEADERBOARD_GLOBAL = ELeaderboardDataRequest::k_ELeaderboardDataRequestGlobal,
		LEADERBOARD_AROUNDUSER = ELeaderboardDataRequest::k_ELeaderboardDataRequestGlobalAroundUser,
		LEADERBOARD_FRIENDS = ELeaderboardDataRequest::k_ELeaderboardDataRequestFriends
	};

	struct LeaderboardEntry
	{
		uint64_t userid;
		int score;
	};

	extern uint64 GetLeaderboard(const UltraEngine::WString& name);
	extern std::vector<LeaderboardEntry> GetLeaderboardEntries(const uint64_t leaderboardid, const LeaderboardDataRequest request = LEADERBOARD_GLOBAL, const int start = 0, const int count = 20);
	extern void SetLeaderboardScore(const uint64_t leaderboardid, const int score);

	//-------------------------------------------------------------------------------
	// Lobbies
	//-------------------------------------------------------------------------------

	enum LobbyType
	{
		LOBBY_PRIVATE = k_ELobbyTypePrivate,
		LOBBY_PUBLIC = k_ELobbyTypePublic,
		LOBBY_FRIENDS = k_ELobbyTypeFriendsOnly
	};

	extern void InviteFriends(const uint64_t lobbyid);
	extern uint64_t CreateLobby(const LobbyType type = LOBBY_PUBLIC, const int maxplayers = 16);
	extern std::vector<uint64_t> GetLobbyMembers(uint64_t lobbyid);
	extern uint64_t GetLobbyOwner(uint64_t lobbyid);
	extern bool SetLobbyOwner(uint64_t lobbyid, uint64_t userid);
	extern bool SetLobbyProperty(uint64_t lobbyid, const UltraEngine::WString& key, const UltraEngine::WString& value);
	extern UltraEngine::WString GetLobbyProperty(uint64_t lobbyid, const UltraEngine::WString& key);
	extern bool JoinLobby(const uint64_t lobbyid);
	extern void LeaveLobby(const uint64_t lobbyid);
	extern std::vector<uint64_t> GetLobbies(const std::map<UltraEngine::WString, UltraEngine::WString>& attributes = {});
	extern uint64_t CurrentLobby();
	//extern bool SetLobbyMaxPlayers(uint64_t lobbyid, const int maxplayers);
	extern int GetLobbyCapacity(uint64_t lobbyid);

	//https://www.ultraengine.com/community/topic/9663-introduction-to-steam-code-in-leadwerks/#comment-73524
	class CallbackManager
	{
	public:
		CallbackManager() : m_CallbackGameOverlayActivated(this, &CallbackManager::OnGameOverlayActivated), m_CallbackP2PSessionRequest(this, &CallbackManager::OnP2PSessionRequest), m_CallbackLobbyDataUpdate(this, &CallbackManager::OnLobbyDataUpdate), m_CallbackGameLobbyJoinRequested(this, &CallbackManager::OnGameLobbyJoinRequested), m_CallbackChatDataUpdate(this, &CallbackManager::OnLobbyChatUpdate) {}

		// Called when someone invites you to a lobby
		STEAM_CALLBACK(CallbackManager, OnGameLobbyJoinRequested, GameLobbyJoinRequested_t, m_CallbackGameLobbyJoinRequested);

		// Called every time someone joins or leaves a lobby
		STEAM_CALLBACK(CallbackManager, OnLobbyChatUpdate, LobbyChatUpdate_t, m_CallbackChatDataUpdate);

		// Called every time lobby data changes
		STEAM_CALLBACK(CallbackManager, OnLobbyDataUpdate, LobbyDataUpdate_t, m_CallbackLobbyDataUpdate);

		// Called to intialize P2P connection
		STEAM_CALLBACK(CallbackManager, OnP2PSessionRequest, P2PSessionRequest_t, m_CallbackP2PSessionRequest);

		// Called when Steam overlay is shown or hidden
		STEAM_CALLBACK(CallbackManager, OnGameOverlayActivated, GameOverlayActivated_t, m_CallbackGameOverlayActivated);
	};

	//-------------------------------------------------------------------------------
	// Peer-to-peer networking
	//-------------------------------------------------------------------------------

	enum P2PSendMode
	{
		P2PSEND_UNRELIABLE = k_EP2PSendUnreliable,
		P2PSEND_UNRELIABLENODELAY = k_EP2PSendUnreliableNoDelay,
		P2PSEND_RELIABLE = k_EP2PSendReliable,
		P2PSEND_RELIABLEBUFFERED = k_EP2PSendReliableWithBuffering
	};

	class Packet : public UltraEngine::Object
	{
		int samplerate{ 0 };
	public:
		shared_ptr<UltraEngine::Buffer> data;
		uint64_t userid{ 0 };
		int channel{ 0 };

		friend std::shared_ptr<Packet> GetPacket(const int);
		friend void Steamworks::Update();
	};

	extern bool SendPacket(const uint64_t steamid, const UltraEngine::WString& s, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);
	extern bool SendPacket(const uint64_t steamid, std::shared_ptr<UltraEngine::Buffer> data, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);
	extern bool SendPacket(const uint64_t steamid, const void* data, const uint32_t size, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);
	extern std::shared_ptr<Packet> GetPacket(const int channel = 0);
	extern bool Disconnect(const uint64_t userid);
	extern bool BroadcastPacket(const uint64_t lobbyid, const UltraEngine::WString& s, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);
	extern bool BroadcastPacket(const uint64_t lobbyid, std::shared_ptr<UltraEngine::Buffer> data, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);
	extern bool BroadcastPacket(const uint64_t lobbyid, const void* data, const uint32_t size, const int channel = 0, const P2PSendMode sendtype = P2PSEND_UNRELIABLE);

	//-------------------------------------------------------------------------------
	// Voice
	//-------------------------------------------------------------------------------

	extern void RecordVoice(const bool mode);
	extern void FilterVoice(const uint64_t userid, const int channel);

#ifdef LUA_VERSION

	//-------------------------------------------------------------------------------
	// Lua bindings
	//-------------------------------------------------------------------------------

	extern void BindCommands(sol::state* state);

#endif

}