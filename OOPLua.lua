local Combat = {}
Combat.__index = Combat

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Click = ReplicatedStorage.Click
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Creates Combat Object
function Combat.new(player: Player)
	local self = setmetatable({}, Combat)

	self.player = player
	self.character = player.Character or player.CharacterAdded:Wait()
	self.rootPart = self.character:FindFirstChild("HumanoidRootPart")
	
	self.showHitbox = true
	self.canAttack = true
	self.canBlock = true
	self.lastHit = false
	self.kbPower = 5

	self.isBlocking = false
	self.isDashing = false
	self.clickDamage = 4.5
	self.lastHitDamage = 10
	self.combo = 1
	self.maxCombo = 5
	self.comboResetTime = 2.5
	self.comboResetTask = nil

	self.params = OverlapParams.new()
	self.params.FilterDescendantsInstances = { self.character }
	self.params.FilterType = Enum.RaycastFilterType.Exclude

	return self
end

function Combat:BloodEffect(character: Model)
	Click:FireAllClients(character)
end

-- Get Player Function
function Combat:IsPlayer(character: Model)
	return Players:GetPlayerFromCharacter(character)
end

-- Apply Countdown Function
function Combat:ApplyCountdown(seconds: number)
	self.canAttack = false
	self.canBlock = false

	task.delay(seconds, function()
		self.canAttack = true
		self.canBlock = true
		
	end)
end

-- Apply Countdown to Blocking Function
function Combat:ApplyBlockCountdown(seconds: number)
	self.canBlock = false
	self.isBlocking = false
	
	task.delay(seconds, function()
		self.canBlock = true
	end)
end

-- Stun Function
function Combat:SetStun(player: Player)
	local Initializer = require(ServerScriptService.Modules.Initializer)
	Initializer:GetPlayer(player):ApplyCountdown(2.5)
end

-- Get Player Blocking Status Function
function Combat:PlayerIsBlocking(player: Player)
	local Initializer = require(ServerScriptService.Modules.Initializer)
	return Initializer:GetPlayer(player):GetBlocking()
end

-- Show Hitbox Function
function Combat:ShowHitbox(size: Vector3)
	local HITBOX = Instance.new("Part")
	HITBOX.CFrame = self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3
	HITBOX.Size = size
	HITBOX.CanCollide = false
	HITBOX.Anchored = true
	HITBOX.Color = Color3.new(1, 0, 0)
	HITBOX.CastShadow = false
	HITBOX.Transparency = 0.5
	HITBOX.Parent = workspace
	
	Debris:AddItem(HITBOX, 0.1)
	end

-- Normal Click Attack Function
function Combat:Click()

		if not self.canAttack then
			return 
		end

		self.combo += 1

		if self.comboResetTask then
			task.cancel(self.comboResetTask)
		end

		self.comboResetTask = task.delay(self.comboResetTime, function()
			self.combo = 1
		end)

		if self.combo >= self.maxCombo then
			self.combo = 1
			self.kbPower = 70
			self.lastHit = true
			self.canAttack = false
			
			task.delay(0.5, function()
				self.kbPower = 5
			end)

		end

		local hitbox = workspace:GetPartBoundsInBox(
			self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3,
			Vector3.new(5, 5, 5),
			self.params
		)

		local enemy = self:Hitbox(hitbox)
		if enemy then
			self:SetDamage(enemy, "Click")
			self:ApplyKnockback(enemy, self.kbPower)
			self.kbPower = 5
		end

		self:ApplyCountdown(0.2)
	
	if self.showHitbox then
		self:ShowHitbox(Vector3.new(5,5,5))
	end
end

-- Right Click Attack Function
function Combat:RightClick()
	if not self.canAttack then return end
	if self.isBlocking then return end

	local hitbox = workspace:GetPartBoundsInBox(
		self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3,
		Vector3.new(7, 7, 7),
		self.params
	)

	local enemy = self:Hitbox(hitbox)
	if enemy then
		self:SetDamage(enemy, "RightClick")
		self:ApplyKnockback(enemy, 50)
	end

	self:ApplyCountdown(2)
	
	if self.showHitbox then
		self:ShowHitbox(Vector3.new(7,7,7))
	end
end

-- Get the character from hitbox function
function Combat:Hitbox(parts: {BasePart})
	for _, part in parts do
		if part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") and part.Parent.Name ~= "Handle" then
			return part.Parent
		end
	end
	return nil
end

-- Knockback Function
function Combat:ApplyKnockback(character: Model, power: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = math.huge
	linearVelocity.Attachment0 = Instance.new("Attachment", root)
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = self.rootPart.CFrame.LookVector * power
	linearVelocity.Parent = root

	Debris:AddItem(linearVelocity, 0.2)
end

-- Damage Function
function Combat:SetDamage(enemy: Model, clickType: string)
	if not enemy then return end

	local Initializer = require(ServerScriptService.Modules.Initializer)
	local enemyPlayer = self:IsPlayer(enemy)
	local humanoid = enemy:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Player
	if enemyPlayer then
		if Initializer:GetPlayer(enemyPlayer):GetBlockingStat() and clickType == "Click" then
			return
		end
		
		if Initializer:GetPlayer(enemyPlayer):GetBlockingStat() and clickType == "RightClick" then
			Initializer:GetPlayer(enemyPlayer):ApplyBlockCountdown(3)
		end

		self:SetStun(enemyPlayer)

		if self.lastHit then
			humanoid:TakeDamage(self.lastHitDamage)
			self.lastHit = false
			self:BloodEffect(enemy)
		else
			humanoid:TakeDamage(self.clickDamage)
		end

		-- NPC
	else
		if self.lastHit then
			humanoid:TakeDamage(self.lastHitDamage)
			self.lastHit = false
			self:BloodEffect(enemy)
		else
			humanoid:TakeDamage(self.clickDamage)
		end
	end
end

-- Get Blocking Status Function
function Combat:GetBlockingStat()
	return self.isBlocking
end

-- Blocking On Function
function Combat:BlockOn()
	if not self.canBlock or self.isBlocking then return end
	
	self.isBlocking = true
	self.canAttack = false
end

-- Blocking Off Function
function Combat:BlockOff()
	if not self.isBlocking then return end
	
	self.isBlocking = false
	self.canAttack = true
end

return Combat
