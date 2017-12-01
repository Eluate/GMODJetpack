if CLIENT then
  SWEP.PrintName = "Jetpack 2.4"
  SWEP.Author = "Harold & Vector"
  SWEP.Slot = 4
  SWEP.SlotPos = 1
end

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = GetConVarNumber("jetpack_max_fuel")
SWEP.Primary.Ammo = "AirboatGun"
SWEP.DrawAmmo = true

SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "normal"
SWEP.Category = "Jetpack"
SWEP.UseHands = false
SWEP.DrawCrosshair= false

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.Automatic= false

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

local JetActivate = Sound("hl1/fvox/activated.wav")
local JetDeactivate = Sound("hl1/fvox/deactivated.wav")

SWEP.Weight = 6
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.ThinkRate = 1/25

-- Activates and de-activates the jetpack SWEP
function SWEP:PrimaryAttack()
  self:SetNextPrimaryFire(CurTime() + 3) -- Time between activation and de-activation
  local JetIsOn = self.Owner:GetNWBool("JetEnabled")

  if SERVER then
    self.Owner:SetNWBool("JetEnabled", not JetIsOn)
    if JetIsOn then
      self.Owner:SetAmmo(GetConVarNumber("jetpack_max_fuel"), "AirboatGun")
      self.Owner:PrintMessage( HUD_PRINTCENTER, "Jetpack Deactivated" )
    elseif not JetIsOn then
      self.Owner:PrintMessage( HUD_PRINTCENTER, "Jetpack Activated" )
    end
  elseif CLIENT then
    if JetIsOn then
      surface.PlaySound(JetDeactivate)
    elseif not JetIsOn then
      surface.PlaySound(JetActivate)
    end
  end
end

function SWEP:AddBoostEffect(ply,force)
  if self.NextBoostEffect<CurTime() or force then
    local ed = EffectData()
    ed:SetEntity(ply)
    util.Effect("wt_rocketboots_effect", ed, true, true)
    self.NextBoostEffect = CurTime()+0.95
  end
end

function PowerPercent(fuelRemaning)
  local totalFuel = GetConVarNumber("jetpack_max_fuel")
  local perc = (totalFuel - fuelRemaning) / totalFuel
  if (perc == 0) then
    perc = 0.1
  end
  perc = math.sin(perc * math.pi * 0.5)
  return perc * (GetConVarNumber("jetpack_increase_maximum") - GetConVarNumber("jetpack_increase_minimum")) + GetConVarNumber("jetpack_increase_minimum")
end

-- Code to replace Think Code
function SWEP:Think()
  if SERVER then
    --Thinking time for velocity
    if not self.LastThink then
      self.LastThink = CurTime()
    end
    local Dti = 0 --This would be 1 if thinking was exactly on time. When thinking gets slower, this gets larger, so we should apply the same force every time
    if CurTime()>=self.LastThink+self.ThinkRate then
      local Dt = CurTime()-self.LastThink
      Dti = Dt/self.ThinkRate
      self.LastThink = CurTime()
    end
    for i, ply in ipairs(player.GetAll()) do
      ply:LagCompensation( false )
      if ply:GetNWBool("JetEnabled") then
        --Make our sound
        if not self.Owner.Sound then
          self.Owner.Sound = CreateSound(self, "PhysicsCannister.ThrusterLoop")
          self.Owner.Sound:Play()
          self.Owner.Sound:ChangeVolume(0,0)
        end
		
        if not self.Owner.Sound2 then
          self.Owner.Sound2 = CreateSound(self, "WT_RocketBoots.Thrust")
          self.Owner.Sound2:Play()
          self.Owner.Sound2:ChangeVolume(0,0)
        end
		
		if not self.Owner.Sound.isPlaying() then
			self.Owner.Sound:Play()
			self.Owner.Sound:ChangeVolume(0,0)
		end
		
		if not self.Owner.Sound2.isPlaying() then
			self.Owner.Sound2:Play()
			self.Owner.Sound2:ChangeVolume(0,0)
		end

        --Default for when its not set yet
        if ply:GetNWBool("Boosting") == nil then
          ply:SetNWBool("Boosting", false)
          self.Owner.Sound:ChangeVolume(0,0)
          self.Owner.Sound2:ChangeVolume(0,0)
        end

        --Are we starting or stopping boosting
        if not ply:GetNWBool("Boosting") then
          if (not ply:IsOnGround()) and ply:KeyDown(IN_JUMP) then
            ply.lastBoost = -1
            ply:SetNWBool("Boosting", true)
            self.Owner.Sound:ChangeVolume(1,0.25)
            self.Owner.Sound2:ChangeVolume(0.8,0.25)
            self:AddBoostEffect(ply, true)
            self.NextBoostEffect = CurTime()+0.95
          end
        else
          --we were boosting, are still boosting?
          if (not ply:KeyDown(IN_JUMP)) or ply:IsOnGround() then
            ply.lastBoost = os.clock()
          ply:SetNWBool("Boosting", false)
            self.Owner.Sound:ChangeVolume(0,0.25)
            self.Owner.Sound2:ChangeVolume(0,0.25)
          end
        end

        --We are flying
        if ply:GetNWBool("Boosting") then
          if (ply:GetAmmoCount("AirboatGun") > GetConVarNumber("jetpack_drain_fuel") and ply:KeyDown(IN_JUMP)) then
            ply:RemoveAmmo(GetConVarNumber("jetpack_drain_fuel"), "AirboatGun")
            ply:SetAllowFullRotation(false)
            --Only apply velocity if we are past our thinking time (dti is zero until we hit our think above)
            if Dti > 0 then
              local vertical = Vector(0, 0, 1)
              local horizontal = Vector(0, 0, 0)
              vertical = PowerPercent(ply:GetAmmoCount("AirboatGun")) * vertical * GetConVarNumber("jetpack_force") * Dti
              if (vertical:Length() < GetConVarNumber("jetpack_force_maximum")) then
                vertical = vertical:GetNormalized() * GetConVarNumber("jetpack_force_maximum")
              end
              if ply:KeyDown(IN_FORWARD) then
                horizontal = horizontal + ply:GetForward()
              end
              if ply:KeyDown(IN_BACK) then
                horizontal = horizontal + -ply:GetForward()
              end
              if ply:KeyDown(IN_MOVERIGHT) then
                horizontal = horizontal + ply:GetRight()
              end
              if ply:KeyDown(IN_MOVELEFT) then
                horizontal = horizontal + -ply:GetRight()
              end
              horizontal = horizontal * GetConVarNumber("jetpack_strafe_force") * Dti
              ply:SetVelocity(vertical + horizontal)
            end
            self:AddBoostEffect(ply)
          end
        else
          -- Refresh ammo code - Will actiavte after a certain amount of time has passed.
          if (ply.lastBoost ~= -1 && os.clock() - ply.lastBoost >= GetConVarNumber("jetpack_recharge_reset")) then
            ply:SetAllowFullRotation(false)
            if (ply:GetAmmoCount("AirboatGun") < GetConVarNumber("jetpack_max_fuel")) then
              if (ply:GetAmmoCount("AirboatGun") + GetConVarNumber("jetpack_recharge_rate") > GetConVarNumber("jetpack_max_fuel")) then
                ply:SetAmmo(GetConVarNumber("jetpack_max_fuel"), "AirboatGun", true)
              else
                ply:GiveAmmo(GetConVarNumber("jetpack_recharge_rate"), "AirboatGun", true)
              end
            end
          end
        end
        ply:LagCompensation( false )
      end
    end
  end
end



local function PlayerDied(ply)
    local JetIsOn = ply:GetNWBool("JetEnabled")

    if JetIsOn then
        ply:SetNWBool("JetEnabled",false)
        ply.Sound:Stop()
        ply.Sound2:Stop()
    end
end
hook.Add("PlayerDeath","RemoveDeadJets",PlayerDied)

function SWEP:SecondaryAttack()
  return
end

function SWEP:Initialize()
  self:SetWeaponHoldType(self.HoldType)
  self.Owner:SetNWFloat("NextJetEffect",CurTime())
  self.NextBoostEffect = CurTime()
end

-- Called when swep is in hand
function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime() + .2)
	self.Owner:DrawViewModel(false)
	self.Owner.ShouldReduceFallDamage = true
	return true
end

-- Called when swep is holstered
function SWEP:Holster()
	self.Owner.ShouldReduceFallDamage = false
	return true
end

local function ReduceFallDamage(ent, inflictor, attacker, amount, dmginfo)
	if ent:IsPlayer() and ent.ShouldReduceFallDamage and dmginfo:IsFallDamage() then
		dmginfo:SetDamage(0)
	end
end
hook.Add("EntityTakeDamage", "ReduceFallDamage", ReduceFallDamage)

function SWEP:DrawWorldModel()
  return false
end

function SWEP:Reload()
  return
end
