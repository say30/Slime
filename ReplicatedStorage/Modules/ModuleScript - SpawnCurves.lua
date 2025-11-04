-- from: ReplicatedStorage.Modules.SpawnCurves

-- ReplicatedStorage/Modules/SpawnCurves.lua
local C = {}

function C.clamp(x, a, b) return math.max(a, math.min(b, x)) end
function C.lerp(a, b, t) return a + (b - a) * t end
function C.invlerp(a, b, x) if b==a then return 0 end return (x-a)/(b-a) end

-- Courbe puissance (ease-in/out selon p)
function C.powCurve(x, p)
	x = C.clamp(x, 0, 1)
	if p >= 1 then return x^p else return 1 - (1 - x)^(1/p) end
end

-- Logistique douce entre 0..1 centrée en 0.5
function C.logistic01(x, k)
	k = k or 10
	x = C.clamp(x, 0, 1)
	local z = 1/(1 + math.exp(-k*(x - 0.5)))
	return C.clamp(z, 0, 1)
end

-- Décroissance expo → utile pour pity progressif
function C.expoBoost(miss, threshold, step, maxMul)
	if miss <= threshold then return 1 end
	local extra = miss - threshold
	local mul = 1 + extra * step
	return (maxMul and math.min(mul, maxMul)) or mul
end

-- Normalisation d’un tableau de poids (index 1..n)
function C.normalize(weights)
	local sum = 0
	for i=1,#weights do sum += math.max(0, weights[i] or 0) end
	if sum <= 0 then return weights end
	for i=1,#weights do weights[i] = math.max(0, weights[i] or 0) / sum end
	return weights
end

-- Tirage pondéré
function C.weightedPick(weights)
	local sum = 0
	for i=1,#weights do sum += weights[i] or 0 end
	if sum <= 0 then return 1 end
	local r = math.random() * sum
	for i=1,#weights do
		r -= (weights[i] or 0)
		if r <= 0 then return i end
	end
	return #weights
end

return C
