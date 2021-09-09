#include <sourcemod>
#include <system2>

#define PLUGIN_VERSION "0.0.1"
#define IPIFY_API_ENDPOINT "https://api.ipify.org"

ConVar tf2pickupOrgApiAddress = null;
ConVar tf2pickupOrgApiKey = null;
ConVar ipv4PublicAddress = null;

public Plugin myinfo = 
{
  name = "tf2pickup.org connector",
  author = "garrappachc",
  description = "Connect your TF2 gameserver to your tf2pickup.org instance",
  version = PLUGIN_VERSION,
  url= "https://github.com/tf2pickup-org"
}

public void OnPluginStart()
{
  tf2pickupOrgApiAddress = CreateConVar("sm_tf2pickuporg_api_address", "", "tf2pickup.org endpoint address");
  tf2pickupOrgApiKey = CreateConVar("sm_tf2pickuporg_api_key", "", "tf2pickup.org API key");
  ipv4PublicAddress = CreateConVar("sm_ipv4_public_address", "", "Public IPv4 address");

  // RegAdminCmd("sm_gameserver_heartbeat", HeartbeatGameServer, "Send a heartbeat to the tf2pickup.org endpoint");

  DiscoverPublicIpV4Address();
}

public void OnPluginEnd()
{

}

public Action HeartbeatGameServer()
{

}

public void DiscoverPublicIpV4Address()
{
  System2HTTPRequest request = new System2HTTPRequest(IpDiscoveryHttpCallback, IPIFY_API_ENDPOINT);
  request.GET();
  delete request;
}

public void IpDiscoveryHttpCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
  if (!success) {
    char url[128];
    request.GetURL(url, sizeof(url));
    PrintToServer("ERROR: %s failed: %s", url, error);
    return;
  }

  char ipAddress[16];
  response.GetContent(ipAddress, sizeof(ipAddress));
  ipv4PublicAddress.SetString(ipAddress);
  PrintToServer("Public IPv4 address is %s", ipAddress);
}
