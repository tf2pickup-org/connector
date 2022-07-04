#include <sourcemod>
#include <system2>

#define PLUGIN_VERSION "0.4.1"

ConVar tf2pickupOrgApiAddress = null;
ConVar tf2pickupOrgSecret = null;
ConVar tf2pickupOrgPriority = null;
ConVar tf2pickupOrgOverrideInternalAddress = null;
Handle timer = null;
char publicIpAddress[64];

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

  tf2pickupOrgPriority = CreateConVar("sm_tf2pickuporg_priority", "1", "gameserver priority", _, true, -9999.99, true, 9999.99);

  tf2pickupOrgOverrideInternalAddress = CreateConVar("sm_tf2pickuporg_override_internal_address", "", "override internal game server address");
  tf2pickupOrgOverrideInternalAddress.AddChangeHook(OnApiAddressOrSecretChange);

  RegServerCmd("sm_tf2pickuporg_heartbeat", CommandHeartbeat);
  ResolvePublicIpAddress();
  delete request;
}

public void OnPluginEnd()
{

}

public void ResolvePublicIpAddress()
{
  // int ipAddr[4];
  // SteamWorks_GetPublicIP(ipAddr);

  // char address[64];
  // Format(address, sizeof(address), "%d.%d.%d.%d", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  System2HTTPRequest request = new System2HTTPRequest(PublicIpCallback, "https://api.ipify.org");
  request.SetUserAgent("tf2pickup.org connector plugin/%s", PLUGIN_VERSION);
  request.GET();
}

public void PublicIpCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
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

  System2HTTPRequest request = new System2HTTPRequest(HeartbeatHttpCallback, "%s/static-game-servers/", apiAddress);
  request.SetHeader("Authorization", "secret %s", secret);
  request.SetHeader("Content-Type", "application/x-www-form-urlencoded");

  char address[64];
  System2_URLEncode(address, sizeof(address), publicIpAddress);

  char port[6];
  GetConVarString(FindConVar("hostport"), port, sizeof(port));

  char name[64];
  GetConVarString(FindConVar("hostname"), name, sizeof(name));
  System2_URLEncode(name, sizeof(name), name);

  char rconPassword[64];
  GetConVarString(FindConVar("rcon_password"), rconPassword, sizeof(rconPassword));
  System2_URLEncode(rconPassword, sizeof(rconPassword), rconPassword);

  char data[256];
  Format(data, sizeof(data), "address=%s&port=%s&name=%s&rconPassword=%s",
    address, port, name, rconPassword);

  int priority = tf2pickupOrgPriority.IntValue;
  Format(data, sizeof(data), "%s&priority=%d", data, priority);

  char overrideInternalAddress[64];
  tf2pickupOrgOverrideInternalAddress.GetString(overrideInternalAddress, sizeof(overrideInternalAddress));

  if (!StrEqual(overrideInternalAddress, "")) {
    System2_URLEncode(overrideInternalAddress, sizeof(overrideInternalAddress), overrideInternalAddress);
    Format(data, sizeof(data), "%s&internalIpAddress=%s", data, overrideInternalAddress);
  }

  request.SetData("%s", data);
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
