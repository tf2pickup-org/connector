#include <sourcemod>
#include <system2>
#include <SteamWorks>

#define PLUGIN_VERSION "0.2.1"

ConVar tf2pickupOrgApiAddress = null;
ConVar tf2pickupOrgSecret = null;
ConVar tf2pickupOrgVoiceChannelName = null;
ConVar tf2pickupOrgPriority = null;
Handle timer = null;

public Plugin myinfo = 
{
  name = "tf2pickup.org connector",
  author = "garrappachc",
  description = "Connect a TF2 gameserver to your tf2pickup.org instance",
  version = PLUGIN_VERSION,
  url = "https://github.com/tf2pickup-org"
}

public void OnPluginStart()
{
  tf2pickupOrgApiAddress = CreateConVar("sm_tf2pickuporg_api_address", "", "tf2pickup.org endpoint address");
  tf2pickupOrgApiAddress.AddChangeHook(OnApiAddressOrSecretChange);

  tf2pickupOrgSecret = CreateConVar("sm_tf2pickuporg_secret", "", "tf2pickup.org gameserver secret");
  tf2pickupOrgSecret.AddChangeHook(OnApiAddressOrSecretChange);

  tf2pickupOrgVoiceChannelName = CreateConVar("sm_tf2pickuporg_voice_channel_name", "", "gameserver voice channel name");
  tf2pickupOrgPriority = CreateConVar("sm_tf2pickuporg_priority", "1", "gameserver priority", 0, true, -9999.99, true, 9999.99);

  RegServerCmd("sm_tf2pickuporg_heartbeat", CommandHeartbeat);
}

public void OnPluginEnd()
{

}

public void OnApiAddressOrSecretChange(ConVar convar, char[] oldValue, char[] newValue)
{
  if (timer != null) {
    KillTimer(timer);
  }

  char endpoint[128];
  tf2pickupOrgApiAddress.GetString(endpoint, sizeof(endpoint));

  char secret[128];
  tf2pickupOrgSecret.GetString(secret, sizeof(secret));

  if (!StrEqual(endpoint, "") && !StrEqual(secret, "")) {
    HeartbeatGameServer(null);
    timer = CreateTimer(60.0, HeartbeatGameServer, _, TIMER_REPEAT);
  }
}

public Action CommandHeartbeat(int args)
{
  return HeartbeatGameServer(null);
}

public Action HeartbeatGameServer(Handle timerHandle)
{
  char apiAddress[128];
  tf2pickupOrgApiAddress.GetString(apiAddress, sizeof(apiAddress));

  char secret[128];
  tf2pickupOrgSecret.GetString(secret, sizeof(secret));

  if (StrEqual(apiAddress, "") || StrEqual(secret, "")) {
    return Plugin_Stop;
  }

  int ipAddr[4];
  SteamWorks_GetPublicIP(ipAddr);

  char address[64];
  Format(address, sizeof(address), "%d.%d.%d.%d", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  System2_URLEncode(address, sizeof(address), address);

  char port[6];
  GetConVarString(FindConVar("hostport"), port, sizeof(port));

  char name[64];
  GetConVarString(FindConVar("hostname"), name, sizeof(name));
  System2_URLEncode(name, sizeof(name), name);

  char rconPassword[64];
  GetConVarString(FindConVar("rcon_password"), rconPassword, sizeof(rconPassword));
  System2_URLEncode(rconPassword, sizeof(rconPassword), rconPassword);

  char voiceChannelName[64];
  tf2pickupOrgVoiceChannelName.GetString(voiceChannelName, sizeof(voiceChannelName));
  System2_URLEncode(voiceChannelName, sizeof(voiceChannelName), voiceChannelName);

  int priority = tf2pickupOrgPriority.IntValue;

  System2HTTPRequest request = new System2HTTPRequest(HeartbeatHttpCallback, "%s/game-servers/", apiAddress);
  request.SetHeader("Authorization", "secret %s", secret);
  request.SetHeader("Content-Type", "application/x-www-form-urlencoded");
  request.SetData("address=%s&port=%s&name=%s&rconPassword=%s&voiceChannelName=%s&priority=%d",
    address, port, name, rconPassword, voiceChannelName, priority);
  request.SetUserAgent("tf2pickup.org connector plugin/%s", PLUGIN_VERSION);
  request.POST();
  delete request;

  return Plugin_Continue;
}

public void HeartbeatHttpCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
  if (!success) {
    char url[128];
    request.GetURL(url, sizeof(url));
    PrintToServer("ERROR: %s failed: %s", url, error);
    return;
  }

  char buf[1024];
  response.GetContent(buf, sizeof(buf));
  PrintToServer("%s", buf);
}
