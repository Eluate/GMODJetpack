if SERVER then
    AddCSLuaFile()
    -- existing
    CreateConVar("jetpack_drain_fuel", 1,{FCVAR_ARCHIVE},"How quickly the Jetpack drains fuel. (Default: 1)")
    CreateConVar("jetpack_max_fuel", 200,{FCVAR_ARCHIVE},"Maximum fuel of the jetpack. (Default: 200)")

    -- New variables for CONSTANT declaration.
    CreateConVar("jetpack_recharge_reset", 1, {FVCAR_ARCHIVE}, "How long until the jetpack waits to start refueling. (Default: 1)")
    CreateConVar("jetpack_recharge_rate", 3, {FVCAR_ARCHIVE}, "How fast the jetpack recharges fuel (Default: 5)")
    CreateConVar("jetpack_force", 100, {FVCAR_ARCHIVE}, "Base force of the Jetpack (Default: 100)")
    CreateConVar("jetpack_force_maximum", 25, {FVCAR_ARCHIVE}, "Maximum force of the Jetpack, i.e movement vertically (Default: 25)")
    CreateConVar("jetpack_strafe_force", 10, {FVCAR_ARCHIVE}, "Strafing force of the Jetpack, i.e movement sideways and forwards (Default: 20)")
    -- Best to leave these two below alone unless you know how they affect the JetPack.
    CreateConVar("jetpack_increase_minimum", 0.2, {FVCAR_ARCHIVE}, "Minimum delta change of the Jetpack (Default: 0.2)")
    CreateConVar("jetpack_increase_maximum", 0.4, {FVCAR_ARCHIVE}, "Maximum delta change of the Jetpack (Default: 0.4)")
	CreateConVar("jetpack_HUD", 1, {FVCAR_ARCHIVE}, "Whether the user will see the HUD.")
end

--Send files to client
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

--Include shared code
include('shared.lua')

--Serverside only code below here
