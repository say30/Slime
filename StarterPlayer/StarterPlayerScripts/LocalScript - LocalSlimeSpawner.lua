-- from: StarterPlayer.StarterPlayerScripts.LocalSlimeSpawner

-- LocalSlimeSpawner.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
LP.CharacterAdded:Wait()

local Plateau      = Workspace:WaitForChild("Part")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local SpawnEvent   = Remotes:WaitForChild("SpawnSlimeEvent")
local PurchaseFunc = Remotes:WaitForChild("PurchaseSlime")
local SlimesFolder = ReplicatedStorage:WaitForChild("Slimes")
local Balance      = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameBalance"))
local Billboard    = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SlimeBillboard"))

local MAX_LOCAL=10; local VIEW_DIST=60
local LIFETIME_MIN=40; local LIFETIME_MAX=43
local LAND_EPSILON=0.05
local WANDER_MARGIN=4
local WANDER_STEP_MIN=3; local WANDER_STEP_MAX=6
local WANDER_DUR_MIN=2.0; local WANDER_DUR_MAX=3.6
local WANDER_PAUSE_MIN=0.8; local WANDER_PAUSE_MAX=1.4

local function plateauTopY() return Plateau.Position.Y + Plateau.Size.Y*0.5 end

local function anchorGhost(model)
	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false end
	end
end

local function getBottomY(model) local cf,sz=model:GetBoundingBox() return cf.Position.Y - sz.Y*0.5 end
local function yawOnly(cf, yaw)
	local pos=cf.Position; if not yaw then local look=cf.LookVector; yaw=math.atan2(-look.X,-look.Z) end
	return CFrame.new(pos)*CFrame.Angles(0,yaw,0)
end

local function tweenPivot(model, fromCF, toCF, dur, style, dir)
	style=style or Enum.EasingStyle.Quad; dir=dir or Enum.EasingDirection.Out
	local nv=Instance.new("NumberValue"); nv.Value=0
	local tw=TweenService:Create(nv, TweenInfo.new(dur, style, dir), {Value=1})
	nv.Changed:Connect(function(v) model:PivotTo(fromCF:Lerp(toCF, v)) end)
	tw.Completed:Connect(function() nv:Destroy() end)
	tw:Play(); tw.Completed:Wait()
end

local function clampOnPlateauXZ(x,z,margin)
	margin=margin or WANDER_MARGIN
	local localV = Plateau.CFrame:PointToObjectSpace(Vector3.new(x, Plateau.Position.Y, z))
	local halfX, halfZ = Plateau.Size.X/2 - margin, Plateau.Size.Z/2 - margin
	localV = Vector3.new(math.clamp(localV.X, -halfX, halfX), 0, math.clamp(localV.Z, -halfZ, halfZ))
	local world = Plateau.CFrame:PointToWorldSpace(localV)
	return world.X, world.Z
end

local function short(n)
	if n>=1e12 then return string.format("%.2fT",n/1e12)
	elseif n>=1e9 then return string.format("%.2fB",n/1e9)
	elseif n>=1e6 then return string.format("%.2fM",n/1e6)
	elseif n>=1e3 then return string.format("%.2fK",n/1e3)
	else return tostring(math.floor(n+0.5)) end
end

local function buildBillboard(model, offer)
	local rarityName = Balance.Rarities[offer.rarityIndex] or "?"
	-- ⬇️ Affichage arrondi (on garde la vraie valeur dans offer.prodPerSec pour la logique)
	local prodInt = math.floor((offer.prodPerSec or 0) + 0.5)

	local data = {
		mood       = offer.mood,
		sizeName   = offer.sizeName,
		rarityName = rarityName,
		stateName  = nil,
		prodText   = string.format("%d gél/s", prodInt), -- ⬅️ chiffres ronds
		priceText  = tostring(offer.price or 0),
	}

	local bb = Billboard.Build(model, data); if not bb then return end

	-- distance gating par joueur (inchangé)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local hb; hb = RunService.Heartbeat:Connect(function()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or not root or not root.Parent then
			bb.Enabled=false
		else
			bb.Enabled = (hrp.Position - root.Position).Magnitude <= VIEW_DIST
		end
		if not model.Parent then hb:Disconnect() end
	end)
end

local function landClean(model, startPos)
	local initialYaw = math.random()*math.pi*2
	model:PivotTo(yawOnly(CFrame.new(startPos), initialYaw))
	local currentBottom = getBottomY(model)
	local targetBottomY = plateauTopY() + LAND_EPSILON
	local deltaY = targetBottomY - currentBottom
	local fromCF = model:GetPivot()
	local toCF = yawOnly(CFrame.new(fromCF.Position.X, fromCF.Position.Y + deltaY, fromCF.Position.Z), initialYaw)
	tweenPivot(model, fromCF, toCF, 1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local function startWander(model)
	task.spawn(function()
		while model.Parent do
			local pivot=model:GetPivot(); local cur=pivot.Position
			local r = WANDER_STEP_MIN + math.random()*(WANDER_STEP_MAX-WANDER_STEP_MIN)
			local a = math.random()*math.pi*2
			local rawX,rawZ = cur.X + r*math.cos(a), cur.Z + r*math.sin(a)
			local cx,cz = clampOnPlateauXZ(rawX, rawZ, WANDER_MARGIN)
			local goal = Vector3.new(cx, cur.Y, cz)
			local dist=(goal-cur).Magnitude
			local dur = math.clamp(dist/3.5, WANDER_DUR_MIN, WANDER_DUR_MAX) -- lent
			local fromCF=yawOnly(pivot)
			local dir=goal-cur; local yaw=math.atan2(-dir.X,-dir.Z)
			local toCF=yawOnly(CFrame.new(goal), yaw)
			tweenPivot(model, fromCF, toCF, dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(WANDER_PAUSE_MIN + math.random()*(WANDER_PAUSE_MAX-WANDER_PAUSE_MIN))
		end
	end)
end

local function asVector3(v)
	if typeof(v)=="Vector3" then return v end
	if typeof(v)=="CFrame" then return v.Position end
	if typeof(v)=="table" then
		return Vector3.new(v.X or v.x or v[1] or 0, v.Y or v.y or v[2] or (plateauTopY()+30), v.Z or v.z or v[3] or 0)
	end
	return Vector3.new(0, plateauTopY()+30, 0)
end

local pool = {} -- {model, conn, dieAt}

local function destroyEntry(e) if not e then return end if e.conn then e.conn:Disconnect() end if e.model and e.model.Parent then e.model:Destroy() end end
local function trimPool() while #pool > MAX_LOCAL do local first=table.remove(pool,1) destroyEntry(first) end end

task.spawn(function()
	while true do
		local now=os.clock()
		for i=#pool,1,-1 do
			local e=pool[i]
			if not e.model or not e.model.Parent or (e.dieAt and now>=e.dieAt) then destroyEntry(e); table.remove(pool,i) end
		end
		task.wait(0.25)
	end
end)

local function addPurchasePrompt(model, offer)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return nil end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText="Acheter"
	prompt.ObjectText=offer.mood.." "..offer.sizeName
	prompt.HoldDuration=0.2
	prompt.MaxActivationDistance=12
	prompt.RequiresLineOfSight=false
	prompt.Parent=root

	return prompt.Triggered:Connect(function(plr)
		if plr ~= LP then return end
		-- ⬇️ on capture la position/orientation EXACTE du slime local
		local localPivot = model:GetPivot()
		local ok, msg = PurchaseFunc:InvokeServer(offer.offerId, localPivot) -- ⬅️ on envoie startCF
		if not ok then
			pcall(function()
				game:GetService("StarterGui"):SetCore("SendNotification",{
					Title="Achat", Text=msg or "Refusé", Duration=2
				})
			end)
			return
		end
		-- despawn immédiat du local (tu le fais déjà)
		if model and model.Parent then model:Destroy() end
	end)
end

local function spawnLocal(offer)
	local moodFolder = SlimesFolder:FindFirstChild(offer.mood); if not moodFolder then return end
	local base = moodFolder:FindFirstChild(offer.mood.." "..offer.sizeName); if not base then return end
	local clone = base:Clone(); clone.Parent = Workspace; anchorGhost(clone)
	local startPos = asVector3(offer.position)
	landClean(clone, startPos)
	buildBillboard(clone, offer)
	local conn = addPurchasePrompt(clone, offer)
	startWander(clone)
	local life = LIFETIME_MIN + math.random()*(LIFETIME_MAX-LIFETIME_MIN)
	table.insert(pool, {model=clone, conn=conn, dieAt=os.clock()+life})
	trimPool()
end

SpawnEvent.OnClientEvent:Connect(function(payload)
	if typeof(payload)~="table" then return end
	spawnLocal(payload)
end)
