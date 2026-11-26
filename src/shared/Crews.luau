--!strict
-- Crew rules as pure functions, so they can be tested offline.

local Crews = {}

-- Which crew a new player joins: the emptiest one that has room
-- (ties go to the lowest number). nil if every crew is full.
function Crews.pick(counts: { number }, crewCount: number, crewSize: number): number?
	local best: number? = nil
	for c = 1, crewCount do
		local n = counts[c] or 0
		if n < crewSize and (best == nil or n < (counts[best] or 0)) then
			best = c
		end
	end
	return best
end

-- End of a run for one crew. Returns whether the quota was met, the next
-- quota, and the cash each member takes home.
function Crews.settle(quota: number, banked: number, members: number, growth: number, baseQuota: number): (boolean, number, number)
	if banked >= quota then
		local nextQuota = math.floor(quota * growth / 10 + 0.5) * 10
		local each = if members > 0 then math.floor(banked / members) else 0
		return true, nextQuota, each
	end
	return false, baseQuota, 0
end

return Crews
