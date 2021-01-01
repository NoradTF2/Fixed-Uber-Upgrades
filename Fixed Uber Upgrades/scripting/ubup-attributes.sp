// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <dhooks>

// Plugin Info
public Plugin:myinfo =
{
	name = "UberUpgrades Custom Attribues",
	author = "Razor",
	description = "Plugin for handling custom attributes.",
	version = "2.0",
	url = "n/a",
}
//Variables
new bool:b_Hooked[MAXPLAYERS+1];
Handle g_DHookGrenadeGetDamageRadius;


stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////Actual Hooks & Functions////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// On Plugin Start
public OnPluginStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == false)
			{
				b_Hooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
	CreateTimer(0.1, Timer_GiveHealth, _, TIMER_REPEAT);
	Handle hGameConf = LoadGameConfigFile("tf2.fixeduu");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata for ubup-attributes.");
	}
	g_DHookGrenadeGetDamageRadius = DHookCreateFromConf(hGameConf,"CBaseGrenade::GetDamageRadius()");
	delete hGameConf;
}
public OnPluginEnd()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == true)
			{
				b_Hooked[i] = false;
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKUnhook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
}
public OnMapStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == false)
			{
				b_Hooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	}
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
		}
	}
}
public Action:Timer_GiveHealth(Handle:timer)//give health every 0.1 seconds
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
			if(RegenActive != Address_Null)
			{
				new Float:RegenPerSecond = TF2Attrib_GetValue(RegenActive);
				new Float:RegenPerTick = RegenPerSecond/10;
				new Address:HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
				{
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				}
				new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				new clientMaxHealth = TF2_GetMaxHealth(client);
				if(clientHealth < clientMaxHealth)
				{
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
					}
				}
			}
		}
	}
}
public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			//Firerate for Secondaries
			new CWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			new melee = GetPlayerWeaponSlot(i,2)
			new primary = GetPlayerWeaponSlot(i,0)
			if(IsValidEntity(CWeapon))
			{
				if(IsValidEntity(melee) && CWeapon == melee){
					continue;
				}
				if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(i) == TFClass_Sniper){
					continue;
				}
				if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(i) == TFClass_Heavy){
					continue;
				}
				new Float:SecondaryROF = 1.0;
				new Address:Firerate1 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
				new Address:Firerate2 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
				new Address:Firerate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
				new Address:Firerate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");
				if(Firerate1 != Address_Null)
				{
					new Float:Firerate1Amount = TF2Attrib_GetValue(Firerate1);
					SecondaryROF =  SecondaryROF/Firerate1Amount;
				}
				if(Firerate2 != Address_Null)
				{
					new Float:Firerate2Amount = TF2Attrib_GetValue(Firerate2);
					SecondaryROF =  SecondaryROF/Firerate2Amount;
				}
				if(Firerate3 != Address_Null)
				{
					new Float:Firerate3Amount = TF2Attrib_GetValue(Firerate3);
					SecondaryROF =  SecondaryROF/Firerate3Amount;
				}
				if(Firerate4 != Address_Null)
				{
					new Float:Firerate4Amount = TF2Attrib_GetValue(Firerate4);
					SecondaryROF =  SecondaryROF/Firerate4Amount;
				}
				SecondaryROF = Pow(SecondaryROF, 0.4);
				new Float:m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
				new Float:SeTime = (m_flNextSecondaryAttack - GetGameTime()) - ((SecondaryROF - 1.0) / (1/GetTickInterval()));
				new Float:FinalS = SeTime+GetGameTime();
				SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
			}
		}
	}
}
//Expect this to be changed in the future.
//public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
//	if (IsValidClient(client))
//	{
//	}
//}
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (hitgroup == 1)
	{
		new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			new Address:HeadshotsActive = TF2Attrib_GetByName(CWeapon, "charge time decreased");
			if(HeadshotsActive != Address_Null)
			{
				damagetype |= DMG_CRIT;
				new Float:HeadshotDMG = TF2Attrib_GetValue(HeadshotsActive);
				damage *= HeadshotDMG;
				return Plugin_Changed;
			}
		}
	}
    return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(attacker) && IsValidEntity(weapon))
	{
		new Address:overrideProj = TF2Attrib_GetByName(weapon, "override projectile type");//Adding support for damage increase on the lightning orb override.
		if(overrideProj != Address_Null && TF2Attrib_GetValue(overrideProj) == 31)
		{
			new Address:DMGVSPlayer = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
			new Address:DamageBonusHidden = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
			new Address:DamagePenalty = TF2Attrib_GetByName(weapon, "damage penalty");
			new Address:DamageBonus = TF2Attrib_GetByName(weapon, "damage bonus");
			new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
			
			if(DMGVSPlayer != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DMGVSPlayer);
			}
			if(DamageBonusHidden != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamageBonusHidden);
			}
			if(DamagePenalty != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamagePenalty);
			}
			if(DamageBonus != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamageBonus);
			}
			if(bulletspershot != Address_Null)
			{
				damage *= TF2Attrib_GetValue(bulletspershot);
			}
		}
		//Detection for Gas Passer Explosion damage
		if(damagetype & DMG_SLASH && damagecustom == 3 && weapon == GetPlayerWeaponSlot(attacker,1))
		{
			new Address:fireRes = TF2Attrib_GetByName(victim, "dmg taken from fire reduced");
			new Address:rangedRes = TF2Attrib_GetByName(victim, "dmg from ranged reduced");
			if(fireRes != Address_Null)
				damage *= TF2Attrib_GetValue(fireRes);
			if(rangedRes != Address_Null)
				damage *= TF2Attrib_GetValue(rangedRes);

			new Address:dmgMult = TF2Attrib_GetByName(weapon, "melee range multiplier");
			if(dmgMult != Address_Null)
				damage *= TF2Attrib_GetValue(dmgMult);
		}
	}
	if(damage < 0.0)// Make sure you can't deal negative damage....
	{
		damage = 0.0;
	}
		/*//debug
		PrintToChatAll("weapon %i", weapon);
		PrintToChatAll("attacker %i", attacker);
		PrintToChatAll("victim %i", victim);
		PrintToChatAll("inflictor %i", inflictor);
		PrintToChatAll("damagetype %i", damagetype);
		PrintToChatAll("damagecustom %i", damagecustom);
		PrintToChatAll(" ");
		
		if(damagetype & DMG_BULLET)
		{
			PrintToChatAll("Bullet");
		}
		if(damagetype & DMG_SLASH)
		{
			PrintToChatAll("Slash");
		}
		if(damagetype & DMG_BURN)
		{
			PrintToChatAll("Burn");
		}
		if(damagetype & DMG_VEHICLE)
		{
			PrintToChatAll("vehicle");
		}
		if(damagetype & DMG_FALL)
		{
			PrintToChatAll("fall");
		}
		if(damagetype & DMG_BLAST)
		{
			PrintToChatAll("blast");
		}
		if(damagetype & DMG_CLUB)
		{
			PrintToChatAll("club");
		}
		if(damagetype & DMG_SHOCK)
		{
			PrintToChatAll("shock");
		}
		if(damagetype & DMG_SONIC)
		{
			PrintToChatAll("sonic");
		}
		if(damagetype & DMG_PREVENT_PHYSICS_FORCE)
		{
			PrintToChatAll("no KB");
		}
		if(damagetype & DMG_ACID)
		{
			PrintToChatAll("crit");
		}
		if(damagetype & DMG_ENERGYBEAM)
		{
			PrintToChatAll("no falloff");
		}
		if(damagetype & DMG_POISON)
		{
			PrintToChatAll("no close falloff");
		}
		if(damagetype & DMG_RADIATION)
		{
			PrintToChatAll("half falloff");
		}
		if(damagetype & DMG_PLASMA)
		{
			PrintToChatAll("ignite victim");
		}
		if(damagetype & DMG_AIRBOAT)
		{
			PrintToChatAll("can headshot");
		}
		*/
	return Plugin_Changed;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(hClientWeapon))
	{
		new Address:override = TF2Attrib_GetByName(hClientWeapon, "override projectile type");
		decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
		if(override != Address_Null)
		{
			new Float:projnum = TF2Attrib_GetValue(override);
			if(projnum == 27)
			{
				new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
				if (IsValidEdict(iEntity)) 
				{
					new iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:Speed = 2000.0;
					new Address:projspeed = TF2Attrib_GetByName(hClientWeapon, "Projectile speed increased");
					if(projspeed != Address_Null)
					{
						Speed *= TF2Attrib_GetValue(projspeed);
					}
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					
					new Float:ProjectileDamage = 90.0;
					
					new Address:DMGVSPlayer = TF2Attrib_GetByName(hClientWeapon, "dmg penalty vs players");
					new Address:DamagePenalty = TF2Attrib_GetByName(hClientWeapon, "damage penalty");
					new Address:DamageBonus = TF2Attrib_GetByName(hClientWeapon, "damage bonus");
					new Address:DamageBonusHidden = TF2Attrib_GetByName(hClientWeapon, "damage bonus HIDDEN");
					
					if(DMGVSPlayer != Address_Null)
					{
						new Float:dmgmult1 = TF2Attrib_GetValue(DMGVSPlayer);
						ProjectileDamage *= dmgmult1;
					}
					if(DamagePenalty != Address_Null)
					{
						new Float:dmgmult2 = TF2Attrib_GetValue(DamagePenalty);
						ProjectileDamage *= dmgmult2;
					}
					if(DamageBonus != Address_Null)
					{
						new Float:dmgmult3 = TF2Attrib_GetValue(DamageBonus);
						ProjectileDamage *= dmgmult3;
					}
					if(DamageBonusHidden != Address_Null)
					{
						new Float:dmgmult4 = TF2Attrib_GetValue(DamageBonusHidden);
						ProjectileDamage *= dmgmult4;
					}
					
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
					
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					DispatchSpawn(iEntity);
				}
			}
			if(projnum == 31)
			{
				new iEntity = CreateEntityByName("tf_projectile_lightningorb");
				if (IsValidEdict(iEntity)) 
				{
					new iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:Speed = 700.0;
					
					new Address:projspeed = TF2Attrib_GetByName(hClientWeapon, "Projectile speed increased");
					if(projspeed != Address_Null)
					{
						Speed *= TF2Attrib_GetValue(projspeed);
					}
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				}
			}
		}
	}
	return Plugin_Handled;
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "tf_projectile_energy_ball") || StrEqual(classname, "tf_projectile_mechanicalarmorb") || StrEqual(classname, "tf_projectile_energy_ring") ||
	StrEqual(classname, "tf_projectile_arrow") || StrEqual(classname, "tf_projectile_healing_bolt"))
	{
		RequestFrame(delay, EntIndexToEntRef(entity)); //RequestFrame just does it better.
	}
	else if(StrEqual(classname, "tf_projectile_jar") || StrEqual(classname, "tf_projectile_jar_milk") || StrEqual(classname, "tf_projectile_jar_gas"))
	{
		DHookEntity(g_DHookGrenadeGetDamageRadius, true, entity,.callback = OnGetGrenadeDamageRadiusPost);
	}
}
public MRESReturn OnGetGrenadeDamageRadiusPost(int grenade, Handle hReturn) {
	float radius = DHookGetReturn(hReturn);
	//copy and pasted from nosoops attribute support.
	//https://github.com/nosoop/SM-TFAttributeSupport/blob/master/scripting/tf2attribute_support.sp
	int weapon = GetEntPropEnt(grenade, Prop_Send, "m_hOriginalLauncher");
	if (!IsValidEntity(weapon)) {
		return MRES_Ignored;
	}
	if(IsValidEntity(weapon))
	{
		new Address:blastActive1 = TF2Attrib_GetByName(weapon, "Blast radius increased");
		new Address:blastActive2 = TF2Attrib_GetByName(weapon, "Blast radius decreased");
		if(blastActive1 != Address_Null)
			radius *= TF2Attrib_GetValue(blastActive1);
		if(blastActive2 != Address_Null)
			radius *= TF2Attrib_GetValue(blastActive2);
	}
	DHookSetReturn(hReturn, radius);
	return MRES_Supercede;
}
delay(ref) 
{ 
    new entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity)) 
    { 
		new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				new Address:projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null){
					new Float:vAngles[3];
					new Float:vPosition[3];
					new Float:vel[3];
					decl Float:vBuffer[3];
					decl Float:vVelocity[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:projspd = TF2Attrib_GetValue(projspeed);
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				}
			}
		}
    } 
}
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}