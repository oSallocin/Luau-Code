local Combat = {} -- creates a empty table to be the Combat class
Combat.__index = Combat -- set up the metatable for Combat

local ServerScriptService = game:GetService("ServerScriptService") -- gets the ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- gets the ReplicatedStorage

local Click = ReplicatedStorage.Click -- gets the Click Event 

local Players = game:GetService("Players") -- gets the Player Event
local Debris = game:GetService("Debris") -- get the Debris event, to remove the hitbox

-- Creates Combat Object
function Combat.new(player: Player) -- create a new instance of combat object for the player
	local self = setmetatable({}, Combat) -- set the metatable of the new table to Combat to inherit the properties and methods of Combat

	self.player = player -- gets the player
	self.character = player.Character or player.CharacterAdded:Wait() -- gets the character
	self.rootPart = self.character:FindFirstChild("HumanoidRootPart") -- gets the root part of the character
	
	self.showHitbox = true -- show the hitbox
	self.canAttack = true -- variable to check if the player can attack
	self.canBlock = true -- variable to check if the player can block
	self.lastHit = false -- variable to check if its the player's last hit
	self.kbPower = 5 -- knockback power

	self.isBlocking = false -- variable to check if the player is blocking
	self.isDashing = false -- variable to check if the player is dashing
	self.clickDamage = 4.5 -- variable to damage of the click attack
	self.lastHitDamage = 10 -- variable to damage of the last hit 
	self.combo = 1 -- variable to check the combo of the player
	self.maxCombo = 5 -- max combo of the player
	self.comboResetTime = 2.5 -- time to reset the combo
	self.comboResetTask = nil -- task to reset the combo

	self.params = OverlapParams.new() -- creates the params for the hitbox
	self.params.FilterDescendantsInstances = { self.character } -- filters the hitbox
	self.params.FilterType = Enum.RaycastFilterType.Exclude -- makes the hitbox not detect the player, so he won't be hitted

	return self -- returns the Combat Object
end

function Combat:BloodEffect(character: Model) 
	Click:FireAllClients(character) -- fire all clients to execute the blood function, so won't have delay bc its being executed on the client
end

-- Get Player Function
function Combat:IsPlayer(character: Model)
	return Players:GetPlayerFromCharacter(character) -- returns the player if the "character" is a player
end

-- Apply Countdown Function
function Combat:ApplyCountdown(seconds: number)
	self.canAttack = false -- set canAttack to false, so player can't attack
	self.canBlock = false -- set canBlock to false, so player can't block

	task.delay(seconds, function() -- after some seconds, the player can attack again
		self.canAttack = true -- set canAttack to true, so player can attack
		self.canBlock = true -- set canBlock to true, so player can block
		
	end)
end

-- Apply Countdown to Blocking Function
function Combat:ApplyBlockCountdown(seconds: number) 
	self.canBlock = false -- set canBlock to false, so player can't block
	self.isBlocking = false -- set isBlocking to false, so if player is blocking then ends it
	
	task.delay(seconds, function() -- after some seconds, the player can block
		self.canBlock = true -- set canBlock to true, so player can block
	end)
end

-- Stun Function
function Combat:SetStun(player: Player)
	local Initializer = require(ServerScriptService.Modules.Initializer) -- gets the combat Initializer Module
	Initializer:GetPlayer(player):ApplyCountdown(2.5) -- executes the function applycountdown, and player can't attack for 2.5 seconds
end

-- Get Player Blocking Status Function
function Combat:PlayerIsBlocking(player: Player)
	local Initializer = require(ServerScriptService.Modules.Initializer) -- gets the combat Initializer Module
	return Initializer:GetPlayer(player):GetBlocking() -- executes the function GetBlocking, that returns the player isBlocking variable
end

-- Show Hitbox Function
function Combat:ShowHitbox(size: Vector3)
	local HITBOX = Instance.new("Part") -- creates the hitbox part
	HITBOX.CFrame = self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3 -- position the hitbox in front of the player
	HITBOX.Size = size -- size of the hitbox
	HITBOX.CanCollide = false -- sets the hitbox part to false, so the hitbox can't collide with other parts
	HITBOX.Anchored = true -- anchor the hitbox, so it won't fall
	HITBOX.Color = Color3.new(1, 0, 0) -- sets the hitbox part color to red
	HITBOX.CastShadow = false -- remove part shadow, to better performance.
	HITBOX.Transparency = 0.5 -- sets the hitbox part transparency to 0.5
	HITBOX.Parent = workspace -- sets the part hitbox parent to workspace
	
	Debris:AddItem(HITBOX, 0.1) -- after 0.1 seconds, destroy the hitbox part
	end

-- Normal Click Attack Function
function Combat:Click()

		if not self.canAttack then -- if the player variable "canAttack" is false then
			return -- returns nothing, and stop the function
		end

		self.combo += 1 -- increase the player combo by 1

		if self.comboResetTask then -- if the "comboResetTask" is not nil then
			task.cancel(self.comboResetTask) -- cancels the task
		end

		self.comboResetTask = task.delay(self.comboResetTime, function() -- after 0.5 seconds, execute the function
			self.combo = 1 -- resets the player combo 
		end)

		if self.combo >= self.maxCombo then -- if the combo  is more or equal than maxCombo  then
			self.combo = 1  -- set combo to 1
			self.kbPower = 70 -- set kbPower to 70
			self.lastHit = true -- set lastHit to true, so next attack will be the lastHit
			self.canAttack = false -- set canAttack to false, so player can't attack
			
			task.delay(0.5, function() -- after 0.5 seconds, execute the function
			self.kbPower = 5 -- set kbPwr to 5, so that when the combo resets and is 1, the enemy will not be pushed with the force of the last hit

			end)

		end

		local hitbox = workspace:GetPartBoundsInBox( -- get all parts in the hitbox
			self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3, -- position the hitbox in front of the player
			Vector3.new(5, 5, 5), -- size of the hitbox
			self.params -- params of the hitbox 
		)

		local enemy = self:Hitbox(hitbox) -- get the enemy from the hitbox
		if enemy then -- if the enemy is not nil then
			self:SetDamage(enemy, "Click") -- set the damage to the enemy
			self:ApplyKnockback(enemy, self.kbPower) -- apply knockback to the enemy
			self.kbPower = 5 -- set kbPower to 5
		end

		self:ApplyCountdown(0.2) -- apply countdown to the player
	
	if self.showHitbox then -- if showHitbox is true then
		self:ShowHitbox(Vector3.new(5,5,5)) -- executes the function that creates the hitbox visual
	end
end

-- Right Click Attack Function
function Combat:RightClick() 
	if not self.canAttack then return end -- if canAttack is false then returns nothing, and stop the function
	if self.isBlocking then return end -- if isBlocking is true then returns nothing, and stop the function	

	local hitbox = workspace:GetPartBoundsInBox( -- get all parts in the hitbox
		self.rootPart.CFrame + self.rootPart.CFrame.LookVector * 3, -- position the hitbox in front of the player
		Vector3.new(7, 7, 7), -- size of the hitbox
		self.params -- params of the hitbox 
	)

	local enemy = self:Hitbox(hitbox) -- get the enemy from the hitbox
	if enemy then -- if the enemy is not nil then
		self:SetDamage(enemy, "RightClick") -- set the damage to the enemy
		self:ApplyKnockback(enemy, 70) -- apply knockback to the enemy
	end

	self:ApplyCountdown(2) -- apply countdown to the player
	
	if self.showHitbox then -- if showHitbox is true then
		self:ShowHitbox(Vector3.new(7,7,7)) -- executes the function that creates the hitbox visual
	end
end

-- Get the character from hitbox function
function Combat:Hitbox(parts: {BasePart})
	for _, part in parts do -- loop through all the parts in the hitbox
		if part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") and part.Parent.Name ~= "Handle" then -- check if the part is a basepart and has a humanoid and the parent of the part name is not "Handle"
			return part.Parent -- return the character
		end
	end
	return nil -- return nil if there is no character
end

-- Knockback Function
function Combat:ApplyKnockback(character: Model, power: number) 
	local root = character:FindFirstChild("HumanoidRootPart") -- find the root part of the character
	if not root then return end -- if there is no root part then return nothing, and stops function
	
	local direction = (character.HumanoidRootPart.Position - self.rootPart.Position).Unit * -power

	local linearVelocity = Instance.new("LinearVelocity") -- create a linear velocity
	linearVelocity.MaxForce = math.huge -- set the max force to infinity
	linearVelocity.Attachment0 = Instance.new("Attachment", root) -- create an attachment on the root part
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World -- set the relative to world
	linearVelocity.VectorVelocity = self.rootPart.CFrame.LookVector * direction -- set the velocity of the linear velocity
	linearVelocity.Parent = root -- parent the linear velocity to the root part

	Debris:AddItem(linearVelocity, 0.2) -- after 0.2 seconds, destroy the linearVelocity
end

-- Damage Function
function Combat:SetDamage(enemy: Model, clickType: string) 
	if not enemy then return end -- if there is no enemy then return nothing, and stops function

	local Initializer = require(ServerScriptService.Modules.Initializer) -- gets the combat Initializer Module
	local enemyPlayer = self:IsPlayer(enemy) -- check if the enemy is a player
	local humanoid = enemy:FindFirstChild("Humanoid") -- find the humanoid of the enemy
	if not humanoid then return end -- if there is no humanoid then return nothing, and stops function

	-- Player
	if enemyPlayer then -- if the enemy is a player then
		if Initializer:GetPlayer(enemyPlayer):GetBlockingStat() and clickType == "Click" then -- if the enemy is blocking and its not a RightClick that break blocks, then
			return -- return nothing, and stops function
		end
		
		if Initializer:GetPlayer(enemyPlayer):GetBlockingStat() and clickType == "RightClick" then -- if the enemy is blocking and its a RightClick, then
			Initializer:GetPlayer(enemyPlayer):ApplyBlockCountdown(3) -- apply block break countdown
		end

		self:SetStun(enemyPlayer) -- stun the enemy, so he can't attack or block while being attacked

		if self.lastHit then -- if lastHit is true then
			humanoid:TakeDamage(self.lastHitDamage) -- take damage
			self.lastHit = false -- set lastHit to false
			self:BloodEffect(enemy) -- executes the blood effect function 
		else -- if lastHit is false then
			humanoid:TakeDamage(self.clickDamage) -- take damage
		end

		-- NPC
	else
		if self.lastHit then -- if lastHit is true then
			humanoid:TakeDamage(self.lastHitDamage) -- take damage
			self.lastHit = false -- set lastHit to false
			self:BloodEffect(enemy) -- executes the blood effect function 
		else -- if lastHit is false then
			humanoid:TakeDamage(self.clickDamage) -- take damage
		end
	end
end

-- Get Blocking Status Function
function Combat:GetBlockingStat() 
	return self.isBlocking -- return the blocking status
end

-- Blocking On Function
function Combat:BlockOn() 
	if not self.canBlock or self.isBlocking then return end -- if the player can't block or is already blocking then return nothing, and stops function
	
	self.isBlocking = true -- set the blocking status to true
	self.canAttack = false -- set the attack status to false
end

-- Blocking Off Function
function Combat:BlockOff() 
	if not self.isBlocking then return end -- if the player is not blocking then return nothing, and stops function
	
	self.isBlocking = false -- set the blocking status to false
	self.canAttack = true -- set the attack status to true
end

-- Quadratic Bezier curve function
local p0 = Vector3.new(0,0,0) -- starting point
local p1 = Vector3.new(0, 10, 10) -- control point (influences curve direction)
local p2 = Vector3.new(10, 0, 20) -- ending point
local segments = 25 -- more segments = smoother curve
local curvePoints = {} -- array to hold Vector3 positions

local function QuadraticBezier(t, p0, p1, p2)
	-- bezier formula: b(t) = (1 - t)^2 * P0 + 2 * (1 - t) * t * P1 + t^2 * P2
	local oneMinusT = 1 - t -- calculate (1 - t)
	local point = (oneMinusT^2) * p0 -- (1 - t)^2 * P0
		+ 2 * oneMinusT * t * p1 -- 2 * (1 - t) * t * P1
		+ (t^2) * p2 -- t^2 * P2
	return point -- return final position on curve
end

for i = 0, segments do
	local t = i / segments --normalized progress (0 to 1)
	local pos = QuadraticBezier(t, p0, p1, p2) -- get position at t
	table.insert(curvePoints, pos) -- store it in the array
	
	local part = Instance.new("Part") -- create part instance
	part.Size = Vector3.new(0.3, 0.3, 0.3) -- small cube size
	part.Shape = Enum.PartType.Ball -- make it spherical
	part.Anchored = true -- keep it static
	part.Position = pos -- place part on curve position
	part.Color = Color3.fromRGB(255, 0, 0) -- red for visibility
	part.Material = Enum.Material.Neon -- makes it stand out
	part.CanCollide = false -- sets the part to false, so it can't collide with other parts
	part.Parent = workspace -- add to Workspace
end

print("i generated a bezier curve with", #curvePoints, " points")

return Combat
