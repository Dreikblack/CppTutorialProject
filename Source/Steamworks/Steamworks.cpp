#pragma once
#include "UltraEngine.h"
#include "Steamworks.h"

namespace Steamworks
{
	using namespace UltraEngine;

	//-------------------------------------------------------------------------------
	// Globals
	//-------------------------------------------------------------------------------

	bool __initialized = false;
	std::map<uint64_t, shared_ptr<Pixmap> > __steamavatars;
	std::shared_ptr<Buffer> __internalbuffer, __internalbuffer2, __decompressionbuffer;
	uint64_t __currentlobby = 0ull;
	bool __recordingmode = false;
	std::map<uint64_t, ALuint> __uservoice;
	std::vector<ALuint> __bufferpool;
	bool __soundinitialized = false;
	SteamHooks __steamhooks;
	CallbackManager* __callbackmanager = nullptr;
	std::map<uint64_t, int> __voicechannel;
	std::vector<Event> __queuedevents;

	bool Initialize()
	{
		if (__initialized) return true;
#ifdef _WIN32
		if (FileType(AppDir() + "/steam_api64.dll") != 1)
		{
			RuntimeError("DLL \"steam_api64.dll\" is missing.");
			exit(1);
		}
#endif
		__initialized = SteamAPI_Init();
		if (__initialized)
		{
			// Hooks for lobby events
			__callbackmanager = new CallbackManager;

			// Get launch command line
			std::array<char, 1024> c;
			auto sz = SteamApps()->GetLaunchCommandLine(c.data(), c.size());
			String s = std::string(c.data(), sz);
			auto sarr = s.Split("");
			for (int n = 0; n < int(sarr.size()) - 1; ++n)
			{
				if (sarr[n] == "+connect_lobby")
				{
					auto lobbyid = _strtoui64(sarr[n + 1].c_str(), nullptr, 10);
					auto info = std::make_shared<LobbyEventInfo>();
					info->lobbyid = lobbyid;
					__queuedevents.push_back(Event(EVENT_LOBBYINVITEACCEPTED, info));
				}
				break;
			}
		}

		return __initialized;
	}

	void Shutdown()
	{
		if (not __initialized) return;
		delete __callbackmanager;
		__callbackmanager = nullptr;
		for (const auto& pair : __uservoice)
		{
			if (pair.second != 0)
			{
				alDeleteSources(1, &pair.second);
			}
		}
		__uservoice.clear();
		if (not __bufferpool.empty())
		{
			alDeleteBuffers(__bufferpool.size(), __bufferpool.data());
			__bufferpool.clear();
		}		
		for (int n = 0; n < 10; ++n)
		{
			if (SteamUserStats()->StoreStats()) break;
			Sleep(100);
		}
		if (not __bufferpool.empty()) alDeleteBuffers(__bufferpool.size(), __bufferpool.data());
		SteamAPI_Shutdown();
		__initialized = false;
	}

	void QueueVoice(const uint64_t userid, shared_ptr<Buffer> data, const int samplerate)
	{
		if (not __soundinitialized) CreateSpeaker();// Force sound initialization
		__soundinitialized = true;

		if (not __uservoice[userid]) alGenSources(1, &__uservoice[userid]);
		auto oalsource = __uservoice[userid];

		// Recycle finished buffers
		ALuint buffer;
		ALint nProcessed;
		alGetSourcei(oalsource, AL_BUFFERS_PROCESSED, &nProcessed);
		for (int i = 0; i < nProcessed; i++)
		{
			alSourceUnqueueBuffers(oalsource, 1, &buffer);
			__bufferpool.push_back(buffer);
		}

		// Get a buffer and set its data
		if (__bufferpool.empty())
		{
			alGenBuffers(1, &buffer);
		}
		else
		{
			buffer = __bufferpool[__bufferpool.size() - 1];
			__bufferpool.pop_back();
		}
		alBufferData(buffer, AL_FORMAT_MONO16, data->Data(), data->GetSize(), samplerate);

		// Queue the buffer
		alSourceQueueBuffers(oalsource, 1, &buffer);

		// Make sure the source is playing
		ALint value;
		alGetSourcei(oalsource, AL_SOURCE_STATE, &value);
		if (value != AL_PLAYING) alSourcePlay(oalsource);
	}

	void Update()
	{
		if (not __initialized) return;
		
		//-------------------------------------------------------------------------------
		// Send voice data
		//-------------------------------------------------------------------------------

		uint32 bytesWritten = 0;
		if (SteamUser()->GetAvailableVoice(&bytesWritten) == k_EVoiceResultOK)
		{
			if (not __internalbuffer) __internalbuffer = CreateBuffer();
			__internalbuffer->Resize(bytesWritten);
			if (SteamUser()->GetVoice(true, __internalbuffer->Data(), __internalbuffer->GetSize(), &bytesWritten) == k_EVoiceResultOK)
			{
				__internalbuffer->Resize(bytesWritten);

				// Testing - send to self
				//SendPacket(GetUserId(), __internalbuffer, CHANNEL_VOICE, P2PSEND_UNRELIABLENODELAY);
				
				auto lobbyid = CurrentLobby();
				if (lobbyid)
				{
					//lobby->Broadcast(__internalbuffer, CHANNEL_VOICE, P2PSEND_UNRELIABLENODELAY);
					auto me = GetUserId();
					int ch = __voicechannel[me];
					auto members = GetLobbyMembers(lobbyid);
					bool succ;
					for (const auto& id : members)
					{
						if (id == me) continue;
						if (__voicechannel[id] != ch) continue;
						succ = SendPacket(id, __internalbuffer, CHANNEL_VOICE, P2PSEND_UNRELIABLENODELAY);
					}
				}
			}
		}

		//-------------------------------------------------------------------------------
		// Receive voice data
		//-------------------------------------------------------------------------------

		while (true)
		{
			auto packet = GetPacket(CHANNEL_VOICE);
			if (not packet) break;

			bool cool = false;
			if (not __decompressionbuffer) __decompressionbuffer = CreateBuffer();
			__decompressionbuffer->Resize(1024 * 20);
			uint32_t bytesWritten;
			int samplerate = SteamUser()->GetVoiceOptimalSampleRate();
			auto result = SteamUser()->DecompressVoice(packet->data->Data(), packet->data->GetSize(), __decompressionbuffer->Data(), __decompressionbuffer->GetSize(), &bytesWritten, samplerate);
			switch (result)
			{
			case k_EVoiceResultBufferTooSmall:
				__decompressionbuffer->Resize(bytesWritten + 1024);
				result = SteamUser()->DecompressVoice(packet->data->Data(), packet->data->GetSize(), __decompressionbuffer->Data(), __decompressionbuffer->GetSize(), &bytesWritten, samplerate);
				switch (result)
				{
				case k_EVoiceResultOK:
					cool = true;
					break;
				case k_EVoiceResultBufferTooSmall:
				default:
					break;
				}
				break;
			case k_EVoiceResultOK:
				__decompressionbuffer->Resize(bytesWritten);
				cool = true;
				break;
			}
			if (cool) QueueVoice(packet->userid, __decompressionbuffer, samplerate);
		}

		// Update callbacks
		SteamAPI_RunCallbacks();

		// Emit all queued events here rather than in callbacks
		for (const Event& e : __queuedevents) EmitEvent(e);
		__queuedevents.clear();
	}

	//-------------------------------------------------------------------------------
	// App
	//-------------------------------------------------------------------------------

	uint64_t GetAppId()
	{
		if (not Initialize()) return 0;
		return SteamUtils()->GetAppID();
	}

	int GetBuildId()
	{
		if (not Initialize()) return 0;
		return SteamApps()->GetAppBuildId();
	}

	bool AppSubscribed(uint64_t appid)
	{
		if (not Initialize()) return false;
		return SteamApps()->BIsSubscribedApp(appid);
	}

	bool AppInstalled(uint64_t appid)
	{
		if (not Initialize()) return false;
		return SteamApps()->BIsAppInstalled(appid);
	}

	bool DlcInstalled(uint64_t appid)
	{
		if (not Initialize()) return false;
		return SteamApps()->BIsDlcInstalled(appid);
	}

	//-------------------------------------------------------------------------------
	// User
	//-------------------------------------------------------------------------------

	uint64_t GetUserId()
	{
		if (not Initialize()) return 0;
		CSteamID id = SteamUser()->GetSteamID();
		return id.ConvertToUint64();
	}

	shared_ptr<Pixmap> GetUserAvatar(const uint64_t userid)
	{
		if (not Initialize()) return nullptr;
		if (__steamavatars[userid] != nullptr) return __steamavatars[userid];
		int image = 0;
		if (SteamFriends()->RequestUserInformation(CSteamID(userid), false)) return NULL;
		image = SteamFriends()->GetLargeFriendAvatar(CSteamID(userid));
		if (image == 0) return nullptr;
		uint32_t w, h;
		SteamUtils()->GetImageSize(image, &w, &h);
		auto pixmap = CreatePixmap(w, h, TEXTURE_RGBA);
		if (not SteamUtils()->GetImageRGBA(image, (uint8*)pixmap->pixels->Data(), w * h * 4)) return nullptr;
		__steamavatars[userid] = pixmap;
		return pixmap;
	}

	WString GetUserName(const uint64_t userid)
	{
		if (not Initialize()) return L"";
		if (SteamFriends()->RequestUserInformation(CSteamID(userid), true)) return L"";
		return std::string(SteamFriends()->GetFriendPersonaName(CSteamID(userid)));
	}

	//-------------------------------------------------------------------------------
	// Stats
	//-------------------------------------------------------------------------------

	bool SetStat(const WString& name, const int i)
	{
		if (not Initialize()) return false;
		String s = name.ToUtf8String();
		SteamUserStats()->SetStat(s.c_str(), i);
	}

	int GetStat(const WString& name)
	{
		if (not Initialize()) return false;
		String s = name.ToUtf8String();
		int32 i = 0;
		if (not SteamUserStats()->GetStat(s.c_str(), &i))
		{
			return -1;
		}
		return i;
	}

	bool AddStat(const WString& name, const int amount)
	{
		if (not Initialize()) return false;
		std::string s = name.ToUtf8String();
		int32 i;
		if (not SteamUserStats()->GetStat(s.c_str(), &i)) return false;
		return SteamUserStats()->SetStat(s.c_str(), i + amount);
	}

	bool UnlockAchievement(const WString& name)
	{
		if (not Initialize()) return false;
		String s = name.ToUtf8String();
		if (SteamUserStats()->SetAchievement(s.c_str()))
		{
			SteamUserStats()->StoreStats();
			return true;
		}
		return false;
	}

	//-------------------------------------------------------------------------------
	// Screenshot
	//-------------------------------------------------------------------------------

	/*bool Screenshot(shared_ptr<Pixmap> pixmap)
	{
		if (not Initialize()) return false;
		WString path = GetPath(PATH_PROGRAMDATA) + "/Ultra Engine/Screenshots";
		WString name = Uuid() + ".jpg";
		if (FileType(path) != 2) CreateDir(path, true);
		String s = (path + "/" + name).ToUtf8String();
		if (not pixmap->Save(path + "/" + name)) return false;
		auto handle = SteamScreenshots()->AddScreenshotToLibrary(s.c_str(), nullptr, pixmap->size.x, pixmap->size.y);
		return handle != INVALID_SCREENSHOT_HANDLE;
	}

	bool Screenshot(const WString& path)
	{
		if (not Initialize()) return false;
		auto pixmap = LoadPixmap(path);
		if (not pixmap) return false;
		String s = path.ToUtf8String();
		auto handle = SteamScreenshots()->AddScreenshotToLibrary(s.c_str(), nullptr, pixmap->size.x, pixmap->size.y);
		return handle != INVALID_SCREENSHOT_HANDLE;
	}*/

	//-------------------------------------------------------------------------------
	// Leaderboards
	//-------------------------------------------------------------------------------

	uint64 GetLeaderboard(const WString& name)
	{
		if (not Initialize()) return 0ull;

		// Get the leaderboard
		String s = name.ToUtf8String();
		//SteamAPICall_t hsteamapicall = SteamUserStats()->FindOrCreateLeaderboard(s.c_str(), (ELeaderboardSortMethod)sortmode, (ELeaderboardDisplayType)type);
		SteamAPICall_t hsteamapicall = SteamUserStats()->FindLeaderboard(s.c_str());
		SteamHooks hooks;
		hooks.LeaderboardFindResult_t_CCallResult.Set(hsteamapicall, &hooks, &SteamHooks::FindOrCreateLeaderboardResultHook);
		if (not hooks.Wait()) return 0ull;
		if (not hooks.m_LeaderboardFindResult_t.m_bLeaderboardFound) return 0ull;
		return hooks.m_LeaderboardFindResult_t.m_hSteamLeaderboard;
	}

	std::vector<LeaderboardEntry> GetLeaderboardEntries(const uint64_t leaderboardid, const LeaderboardDataRequest request, const int start, const int count)
	{
		// Get entries
		SteamUserStats()->DownloadLeaderboardEntries(leaderboardid, ELeaderboardDataRequest(request), start, count);

		LeaderboardEntry_t entry;
		LeaderboardEntry e;

		SteamHooks hooks;
		auto hsteamapicall = SteamUserStats()->DownloadLeaderboardEntries(hooks.m_LeaderboardFindResult_t.m_hSteamLeaderboard, k_ELeaderboardDataRequestGlobal, start, count);
		hooks.LeaderboardScoresDownloaded_t_CCallResult.Set(hsteamapicall, &hooks, &SteamHooks::LeaderboardScoresDownloadedHook);
		if (not hooks.Wait()) return {};

		std::vector<LeaderboardEntry> entries;
		for (int n = 0; n < hooks.m_LeaderboardScoresDownloaded_t.m_cEntryCount; ++n)
		{
			if (SteamUserStats()->GetDownloadedLeaderboardEntry(hooks.m_LeaderboardScoresDownloaded_t.m_hSteamLeaderboardEntries, n, &entry, NULL, 0))
			{
				e.userid = entry.m_steamIDUser.ConvertToUint64();
				e.score = entry.m_nScore;
				entries.push_back(e);
			}
		}
		return entries;
	}

	void SetLeaderboardScore(const uint64_t leaderboardid, const int score)
	{
		SteamUserStats()->UploadLeaderboardScore(leaderboardid, k_ELeaderboardUploadScoreMethodKeepBest, score, nullptr, 0);
	}

	//-------------------------------------------------------------------------------
	// Peer-to-peer networking
	//-------------------------------------------------------------------------------

	bool SendPacket(const uint64_t steamid, const UltraEngine::WString& s, const int channel, const P2PSendMode sendtype)
	{
		String ss = s.ToUtf8String();
		return SendPacket(steamid, ss.c_str(), ss.size(), channel, sendtype);
	}

	bool SendPacket(const uint64_t steamid, std::shared_ptr<UltraEngine::Buffer> data, const int channel, const P2PSendMode sendtype)
	{
		return SendPacket(steamid, data->Data(), data->GetSize(), channel, sendtype);
	}

	bool SendPacket(const uint64_t steamid, const void* data, const uint32_t size, const int channel, const P2PSendMode sendtype)
	{
		//SteamNetworkingIdentity()->
		//SteamNetworkingMessages()->SendMessageToUser()
		if (not Initialize()) return false;
		return SteamNetworking()->SendP2PPacket(CSteamID(uint64(steamid)), data, size, EP2PSend(sendtype), channel);
	}

	std::shared_ptr<Packet> GetPacket(const int channel)
	{
		if (not Initialize()) return nullptr;
		uint32 packetsize;
		if (not SteamNetworking()->IsP2PPacketAvailable(&packetsize, channel)) return nullptr;
		if (not __internalbuffer2) __internalbuffer2 = CreateBuffer();
		auto data = __internalbuffer2;
		data->Resize(packetsize);
		if (not data) return nullptr;
		CSteamID steamid;
		if (not SteamNetworking()->ReadP2PPacket(data->Data(), data->GetSize(), &packetsize, &steamid, channel)) return nullptr;
		auto packet = std::make_shared<Packet>();
		packet->channel = channel;
		packet->userid = steamid.ConvertToUint64();
		packet->data = data;
		return packet;
	}

	bool Disconnect(const uint64_t userid)
	{
		if (not Initialize()) return false;
		return SteamNetworking()->CloseP2PSessionWithUser(CSteamID(userid));
	}

	bool BroadcastPacket(const uint64_t lobbyid, const UltraEngine::WString& s, const int channel, const P2PSendMode sendtype)
	{
		String ss = s.ToUtf8String();
		return BroadcastPacket(lobbyid, ss.c_str(), ss.size(), channel, sendtype);
	}

	bool BroadcastPacket(const uint64_t lobbyid, std::shared_ptr<UltraEngine::Buffer> data, const int channel, const P2PSendMode sendtype)
	{
		return BroadcastPacket(lobbyid, data->Data(), data->GetSize(), channel, sendtype);
	}

	bool BroadcastPacket(const uint64_t lobbyid, const void* data, const uint32_t size, const int channel, const P2PSendMode sendtype)
	{
		if (lobbyid == 0ull) return false;
		if (not Initialize()) return false;
		auto me = GetUserId();
		auto members = GetLobbyMembers(lobbyid);
		bool succ = true;
		for (const auto& id : members)
		{
			if (id == me) continue;
			if (not SteamNetworking()->SendP2PPacket(CSteamID(id), data, size, EP2PSend(sendtype), channel)) succ = false;
		}
		return succ;
	}

	//-------------------------------------------------------------------------------
	// Lobbies
	//-------------------------------------------------------------------------------

	uint64_t CurrentLobby()
	{
		return __currentlobby;
	}

	uint64_t CreateLobby(const LobbyType type, const int maxplayers)
	{
		if (not Initialize()) return 0ll;
		if (__currentlobby) LeaveLobby(__currentlobby);
		auto hsteamapicall = SteamMatchmaking()->CreateLobby(ELobbyType(type), maxplayers);
		SteamHooks hooks;
		hooks.LobbyCreated_t_CCallResult.Set(hsteamapicall, &hooks, &SteamHooks::CreateLobbyHook);
		if (not hooks.Wait()) return 0ll;
		__currentlobby = hooks.m_LobbyCreated_t.m_ulSteamIDLobby;
		//bool succ = JoinLobby(hooks.m_LobbyCreated_t.m_ulSteamIDLobby);
		return hooks.m_LobbyCreated_t.m_ulSteamIDLobby;
	}

	void InviteFriends(const uint64_t lobbyid)
	{
		if (not Initialize()) return;
		SteamFriends()->ActivateGameOverlayInviteDialog(lobbyid);
	}

	bool JoinLobby(const uint64_t lobbyid)
	{
		if (not Initialize()) return false;
		auto prev = CurrentLobby();
		if (prev != lobbyid)
		{
			LeaveLobby(prev);
			__currentlobby = 0ull;
		}
		auto hsteamapicall = SteamMatchmaking()->JoinLobby(lobbyid);
		SteamHooks hooks;
		hooks.LobbyEnter_t_CCallResult.Set(hsteamapicall, &hooks, &SteamHooks::EnterLobbyHook);
		if (not hooks.Wait()) return false;
		if (hooks.m_LobbyEnter_t.m_EChatRoomEnterResponse != k_EChatRoomEnterResponseSuccess) return false;
		__currentlobby = lobbyid;
		auto me = GetUserId();
		auto members = GetLobbyMembers(lobbyid);
		for (const auto id : members)
		{
			if (id != me) SteamNetworking()->AcceptP2PSessionWithUser(id);
		}
		return true;
	}

	void LeaveLobby(const uint64_t lobbyid)
	{
		if (not __initialized) return;
		auto members = GetLobbyMembers(lobbyid);
		for (auto id : members)
		{
			if (id != GetUserId()) Disconnect(id);
		}
		SteamMatchmaking()->LeaveLobby(lobbyid);
		if (lobbyid == __currentlobby) __currentlobby = 0ull;
	}

	/*bool SetLobbyMaxPlayers(uint64_t lobbyid, const int maxplayers)
	{
		return SteamMatchmaking()->SetLobbyMemberLimit(lobbyid, maxplayers);
	}*/

	int GetLobbyCapacity(uint64_t lobbyid)
	{
		return SteamMatchmaking()->GetLobbyMemberLimit(lobbyid);
	}

	bool SetLobbyProperty(uint64_t lobbyid, const UltraEngine::WString& key, const UltraEngine::WString& value)
	{
		return SteamMatchmaking()->SetLobbyData(lobbyid, key.ToUtf8String().c_str(), value.ToUtf8String().c_str());
	}

	UltraEngine::WString GetLobbyProperty(uint64_t lobbyid, const UltraEngine::WString& key)
	{
		return std::string(SteamMatchmaking()->GetLobbyData(lobbyid, key.ToUtf8String().c_str()));
	}

	uint64_t GetLobbyOwner(uint64_t lobbyid)
	{
		return SteamMatchmaking()->GetLobbyOwner(lobbyid).ConvertToUint64();
	}

	bool SetLobbyOwner(uint64_t lobbyid, uint64_t userid)
	{
		return SteamMatchmaking()->SetLobbyOwner(lobbyid, userid);
	}

	std::vector<uint64_t> GetLobbyMembers(uint64_t lobbyid)
	{
		std::vector<uint64_t> members;
		auto cid = CSteamID(lobbyid);
		int count = SteamMatchmaking()->GetNumLobbyMembers(cid);
		members.reserve(count);
		for (int n = 0; n < count; ++n)
		{
			members.push_back(SteamMatchmaking()->GetLobbyMemberByIndex(cid, n).ConvertToUint64());
		}
		auto owner = GetLobbyOwner(lobbyid);
		bool found = false;
		for (int n = 0; n < count; ++n)
		{
			if (members[n] == owner)
			{
				found = true;
				break;
			} 
		}
		if (not found) members.push_back(owner);
		return members;
	}

	std::vector<uint64_t> GetLobbies(const std::map<WString, WString>& attributes)
	{
		//SteamMatchmaking()->AddRequestLobbyListStringFilter("game", "MyGame", k_ELobbyComparisonEqual);// string comparison
		//SteamMatchmaking()->AddRequestLobbyListFilterSlotsAvailable(1);// no full servers
		//SteamMatchmaking()->AddRequestLobbyListDistanceFilter(k_ELobbyDistanceFilterDefault);// region filter
		//SteamMatchmaking()->AddRequestLobbyListResultCountFilter(100);// number of lobbies
		for (auto it = attributes.begin(); it != attributes.end(); it++)
		{
			SteamMatchmaking()->AddRequestLobbyListStringFilter(it->first.ToUtf8String().c_str(), it->second.ToUtf8String().c_str(), k_ELobbyComparisonEqual);
		}
		SteamMatchmaking()->AddRequestLobbyListDistanceFilter(k_ELobbyDistanceFilterWorldwide);
		auto hsteamapicall = SteamMatchmaking()->RequestLobbyList();
		SteamHooks hooks;
		hooks.LobbyMatchList_t_CCallResult.Set(hsteamapicall, &hooks, &SteamHooks::LobbyMatchListHook);
		if (not hooks.Wait()) return {};
		std::vector<uint64_t> lobbies;
		lobbies.reserve(hooks.m_LobbyMatchList_t.m_nLobbiesMatching);
		for (int n = 0; n < hooks.m_LobbyMatchList_t.m_nLobbiesMatching; ++n)
		{
			lobbies.push_back(SteamMatchmaking()->GetLobbyByIndex(n).ConvertToUint64());
		}
		return lobbies;
	}
	 
	void CallbackManager::OnGameLobbyJoinRequested(GameLobbyJoinRequested_t* pParam)
	{
		uint64_t lobbyid = pParam->m_steamIDLobby.ConvertToUint64();
		auto info = std::make_shared<LobbyEventInfo>();
		info->userid = pParam->m_steamIDFriend.ConvertToUint64();
		info->lobbyid = pParam->m_steamIDLobby.ConvertToUint64();
		__queuedevents.push_back(Event(EVENT_LOBBYINVITEACCEPTED, info));
	}

	void CallbackManager::OnLobbyChatUpdate(LobbyChatUpdate_t* pCallback)
	{
		auto info = std::make_shared<LobbyEventInfo>();
		info->lobbyid = pCallback->m_ulSteamIDLobby;
		info->userid = pCallback->m_ulSteamIDUserChanged;
		if ((k_EChatMemberStateChangeEntered & pCallback->m_rgfChatMemberStateChange) != 0)
		{
			__queuedevents.push_back(Event(EVENT_LOBBYUSERJOIN, info));
			SteamNetworking()->AcceptP2PSessionWithUser(pCallback->m_ulSteamIDUserChanged);
		}
		if ((k_EChatMemberStateChangeLeft & pCallback->m_rgfChatMemberStateChange) != 0) __queuedevents.push_back(Event(EVENT_LOBBYUSERLEAVE, info));
		if ((k_EChatMemberStateChangeDisconnected & pCallback->m_rgfChatMemberStateChange) != 0) __queuedevents.push_back(Event(EVENT_LOBBYUSERDISCONNECT, info));
		// Don't know how to activate these:
		//if ((k_EChatMemberStateChangeKicked & pCallback->m_rgfChatMemberStateChange) != 0) EmitEvent(EVENT_LOBBYUSERKICKED, info);
		//if ((k_EChatMemberStateChangeBanned & pCallback->m_rgfChatMemberStateChange) != 0) EmitEvent(EVENT_LOBBYUSERBANNED, info);
	}

	//https://partner.steamgames.com/doc/api/ISteamMatchmaking#LobbyDataUpdate_t
	void CallbackManager::OnLobbyDataUpdate(LobbyDataUpdate_t* pCallback)
	{
		if (not pCallback->m_bSuccess) return;
		if (pCallback->m_ulSteamIDMember == pCallback->m_ulSteamIDLobby)
		{
			auto info = std::make_shared<LobbyEventInfo>();
			info->lobbyid = pCallback->m_ulSteamIDLobby;
			info->userid = GetLobbyOwner(info->lobbyid);
			__queuedevents.push_back(Event(EVENT_LOBBYDATACHANGED, info));
		}
	}

	void CallbackManager::OnP2PSessionRequest(P2PSessionRequest_t* pP2PSessionRequest)
	{
		// always accept packets
		// the packet itself will come through when you call SteamNetworking()->ReadP2PPacket()
		SteamNetworking()->AcceptP2PSessionWithUser(pP2PSessionRequest->m_steamIDRemote);
	}

	void CallbackManager::OnGameOverlayActivated(GameOverlayActivated_t* pCallback)
	{
		__queuedevents.push_back(Event(EVENT_STEAMOVERLAY, nullptr, pCallback->m_bActive));
	}

	//-------------------------------------------------------------------------------
	// Voice
	//-------------------------------------------------------------------------------

	void FilterVoice(const uint64_t userid, const int channel)
	{
		__voicechannel[userid] = channel;
	}

	void RecordVoice(const bool mode)
	{
		if (mode == __recordingmode) return;
		if (mode and CurrentLobby() == 0ull) return;
		if (not Initialize()) return;
		if (mode)
		{
			SteamUser()->StartVoiceRecording();
		}
		else
		{
			SteamUser()->StopVoiceRecording();
		}
		__recordingmode = mode;
	}

#ifdef LUA_VERSION

	//-------------------------------------------------------------------------------
	// Bind commands to Lua state
	//-------------------------------------------------------------------------------

	void BindCommands(sol::state* L)
	{		
		sol::table t(*L, sol::create);
		
		t["EVENT_LOBBYUSERJOIN"] = EVENT_LOBBYUSERJOIN;
		t["EVENT_LOBBYUSERLEAVE"] = EVENT_LOBBYUSERLEAVE;
		t["EVENT_LOBBYUSERDISCONNECT"] = EVENT_LOBBYUSERDISCONNECT;
		t["EVENT_LOBBYINVITEACCEPTED"] = EVENT_LOBBYINVITEACCEPTED;
		t["EVENT_STEAMOVERLAY"] = EVENT_STEAMOVERLAY;

		t["Initialize"] = Steamworks::Initialize;
		t["Shutdown"] = Steamworks::Shutdown;
		t["Update"] = Steamworks::Update;

		//-------------------------------------------------------------------------------
		// User
		//-------------------------------------------------------------------------------
		
		t["GetUserId"] = []() { return int64_t( GetUserId() ); };
		t["GetUserAvatar"] = [](int64_t h) { return GetUserAvatar(h); };
		t["GetUserName"] = [](int64_t h) { return std::string(Steamworks::GetUserName(h).ToUtf8String()); };

		//-------------------------------------------------------------------------------
		// Apps
		//-------------------------------------------------------------------------------

		t["GetAppId"] = Steamworks::GetAppId;
		t["GetBuildId"] = Steamworks::GetBuildId;
		t["AppSubscribed"] = Steamworks::AppSubscribed;
		t["AppInstalled"] = Steamworks::AppInstalled;
		t["DlcInstalled"] = Steamworks::DlcInstalled;

		//-------------------------------------------------------------------------------
		// Statistics and achievements
		//-------------------------------------------------------------------------------

		t["SetStat"] = [](std::string s, int v) { return SetStat(s, v); };
		t["GetStat"] = [](std::string s) { return GetStat(s); };
		t["AddStat"] = sol::overload(
			[](std::string s) { AddStat(s); },
			[](std::string s, int v) { AddStat(s, v); }
		);
		t["UnlockAchievement"] = [](std::string s) { return UnlockAchievement(s); };
		
		//-------------------------------------------------------------------------------
		// Leaderboards
		//-------------------------------------------------------------------------------

		t["LEADERBOARD_GLOBAL"] = LEADERBOARD_GLOBAL;
		t["LEADERBOARD_AROUNDUSER"] = LEADERBOARD_AROUNDUSER;
		t["LEADERBOARD_FRIENDS"] = LEADERBOARD_FRIENDS;
		
		L->new_usertype<Steamworks::LeaderboardEntry>(
			"LeaderboardEntryClass",
			"userid", &LeaderboardEntry::userid,
			"score", &LeaderboardEntry::score
		);

		t["GetLeaderboard"] = [](std::string s) { return GetLeaderboard(s); };
		t["SetLeaderboardScore"] = SetLeaderboardScore;
		t["GetLeaderboardEntries"] = sol::overload(
			[](uint64_t h) { return GetLeaderboardEntries(h); },
			[](uint64_t h, LeaderboardDataRequest r) { return GetLeaderboardEntries(h, r); },
			[](uint64_t h, LeaderboardDataRequest r, int b) { return GetLeaderboardEntries(h, r, b); },
			[](uint64_t h, LeaderboardDataRequest r, int b, int e) { return GetLeaderboardEntries(h, r, b, e); }
		);
		
		//-------------------------------------------------------------------------------
		// Peer-to-peer networking
		//-------------------------------------------------------------------------------

		t["P2PSEND_UNRELIABLE"] = P2PSEND_UNRELIABLE;
		t["P2PSEND_UNRELIABLENODELAY"] = P2PSEND_UNRELIABLENODELAY;
		t["P2PSEND_RELIABLE"] = P2PSEND_RELIABLE;
		t["P2PSEND_RELIABLEBUFFERED"] = P2PSEND_RELIABLEBUFFERED;

		t["Disconnect"] = Steamworks::Disconnect;
		t["GetPacket"] = sol::overload(
			[](int channel) { return Steamworks::GetPacket(channel); },
			[]() { return Steamworks::GetPacket(); }
		);
		t["SendPacket"] = sol::overload(
			[](int64_t h, std::string s, int channel, P2PSendMode sendtype) { return Steamworks::SendPacket(h, s, channel, sendtype); },
			[](int64_t h, std::string s, int channel) { return Steamworks::SendPacket(h, s, channel); },
			[](int64_t h, std::string s) { return Steamworks::SendPacket(h, s); },
			[](int64_t h, shared_ptr<Buffer> s, int channel, P2PSendMode sendtype) { return Steamworks::SendPacket(h, s, channel, sendtype); },
			[](int64_t h, shared_ptr<Buffer> s, int channel) { return Steamworks::SendPacket(h, s, channel); },
			[](int64_t h, shared_ptr<Buffer> s) { return Steamworks::SendPacket(h, s); },
			[](int64_t h, void* s, uint32_t size, int channel, P2PSendMode sendtype) { return Steamworks::SendPacket(h, s, size, channel, sendtype); },
			[](int64_t h, void* s, uint32_t size, int channel) { return Steamworks::SendPacket(h, s, size, channel); },
			[](int64_t h, void* s, uint32_t size) { return Steamworks::SendPacket(h, s, size); }
		);
		t["BroadcastPacket"] = sol::overload(
			[](int64_t h, std::string s, int channel, P2PSendMode sendtype) { return Steamworks::BroadcastPacket(h, s, channel, sendtype); },
			[](int64_t h, std::string s, int channel) { return Steamworks::BroadcastPacket(h, s, channel); },
			[](int64_t h, std::string s) { return Steamworks::BroadcastPacket(h, s); },
			[](int64_t h, shared_ptr<Buffer> s, int channel, P2PSendMode sendtype) { return Steamworks::BroadcastPacket(h, s, channel, sendtype); },
			[](int64_t h, shared_ptr<Buffer> s, int channel) { return Steamworks::BroadcastPacket(h, channel); },
			[](int64_t h, shared_ptr<Buffer> s) { return Steamworks::BroadcastPacket(h, s); },
			[](int64_t h, void* s, uint32_t size, int channel, P2PSendMode sendtype) { return Steamworks::BroadcastPacket(h, s, size, channel, sendtype); },
			[](int64_t h, void* s, uint32_t size, int channel) { return Steamworks::BroadcastPacket(h, s, size, channel); },
			[](int64_t h, void* s, uint32_t size) { return Steamworks::BroadcastPacket(h, s, size); }
		);
		
		L->new_usertype<Steamworks::Packet>(
			"PacketClass",
			sol::base_classes, sol::bases<Object>(),
			"data", &Packet::data,
			"userid", [](Packet& p) { return int64_t(p.userid); },
			"channel", &Packet::channel
		);

		//-------------------------------------------------------------------------------
		// Lobbies
		//-------------------------------------------------------------------------------

		L->new_usertype<Steamworks::LobbyEventInfo>(
			"LobbyEventInfoClass",
			sol::base_classes, sol::bases<Object>(),
			"userid", [](LobbyEventInfo& p) { return int64_t(p.userid); },
			"lobbyid", [](LobbyEventInfo& p) { return int64_t(p.lobbyid); }
		);

		//Function for casting type
		/*L->set("LobbyEventInfo", [](Object* o) {
			std::shared_ptr<LobbyEventInfo> i;
			if (o) i = o->As<LobbyEventInfo>();
			return i;
		});*/

		t["LobbyEventInfo"] = [](Object* o) {
			std::shared_ptr<LobbyEventInfo> i;
			if (o) i = o->As<LobbyEventInfo>();
			return i; };

		t["InviteFriends"] = [](int64_t h) { InviteFriends(h); };
		t["CreateLobby"] = sol::overload(
			[]() { return CreateLobby(); },
			[]( LobbyType t ) { return CreateLobby(t); },
			[]( LobbyType t, int p) { return CreateLobby(t, p); }
		);
		t["GetLobbyMembers"] = GetLobbyMembers;
		/*[](int64_t h) {
			std::vector<int64_t> r;
			auto m = GetLobbyMembers(h);
			r.reserve(m.size());
			for (const auto& id : m) r.push_back(int64_t(id));
			return r;
		};*/
		t["GetLobbyCapacity"] = GetLobbyCapacity;
		//t["SetLobbyMaxPlayers"] = SetLobbyMaxPlayers;
		t["GetLobbyOwner"] = GetLobbyOwner;// [](int64_t h) { return int64_t(GetLobbyOwner(h)); };
		t["JoinLobby"] = JoinLobby;// [](int64_t h) { return JoinLobby(h); };
		t["LeaveLobby"] = LeaveLobby;
		t["GetLobbyProperty"] = [](int64_t h, std::string k) { return std::string( GetLobbyProperty(h, k).ToUtf8String() ); };
		t["SetLobbyProperty"] = [](int64_t h, std::string k, std::string v) { SetLobbyProperty(h, k, v); };
		t["CurrentLobby"] = []() { return int64_t(CurrentLobby()); };
		t["GetLobbies"] = sol::overload(
			[]() {
				auto m = GetLobbies();
				std::vector<int64_t> r;
				r.reserve(m.size());
				for (const auto& id : m)
				{
					r.push_back(int64_t(id));
				}
				return r;
			},
			[](sol::table t) {
				std::map<WString, WString> attr;
				for (const auto& pair : t)
				{
					if (pair.first.is<std::string>() and pair.second.is<std::string>())
					{
						attr[pair.first.as<std::string>()] = pair.second.as<std::string>();
					}
				}
				auto m = GetLobbies(attr);
				std::vector<int64_t> r;
				r.reserve(m.size());
				for (const auto& id : m)
				{
					r.push_back(int64_t(id));
				}
				return r;
			}
		);

		//-------------------------------------------------------------------------------
		// Voice recording
		//-------------------------------------------------------------------------------

		t["RecordVoice"] = Steamworks::RecordVoice;
		t["FilterVoice"] = Steamworks::FilterVoice;

		L->set("Steamworks", t);
	}

#endif
}