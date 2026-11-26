--!strict
-- MonetisationService: the hooks for paid extras. OFF until Jason pastes
-- real IDs into Config.MONETISATION (all 0 by default). Nothing here can
-- spend Robux on its own: Roblox always shows the player its own purchase
-- prompt. Everything sold is cosmetic or helps your whole crew equally.
--   Suit colours pass  -> wardrobe in the safehouse cycles your suit colour
--   Supporter pass     -> amber patch on your suit
--   Crew supply drop   -> energy drink + soft boots for your whole crew

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CrewService = require(script.Parent:WaitForChild("CrewService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local M = Config.MONETISATION
local MonetisationService = {}

local function owns(player: Player, passId: number): boolean
	if passId == 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and result == true
end

local function refreshPasses(player: Player)
	player:SetAttribute("Pass_SuitColours", owns(player, M.SUIT_COLOURS_PASS))
	player:SetAttribute("Pass_Supporter", owns(player, M.SUPPORTER_PASS))
end

-- Called by the safehouse wardrobe prompt.
function MonetisationService.useWardrobe(player: Player)
	if M.SUIT_COLOURS_PASS == 0 then
		return
	end
	if not player:GetAttribute("Pass_SuitColours") then
		MarketplaceService:PromptGamePassPurchase(player, M.SUIT_COLOURS_PASS)
		return
	end
	local current = (player:GetAttribute("SuitColour") or 1) :: number
	local nextColour = current % #Config.SUIT_COLOURS + 1
	player:SetAttribute("SuitColour", nextColour)
	player:LoadCharacter() -- re-dress in the new colour (you stay in the safehouse)
end

-- Called by the supply-drop prompt.
function MonetisationService.promptSupplyDrop(player: Player)
	if M.CREW_SUPPLY_PRODUCT ~= 0 then
		MarketplaceService:PromptProductPurchase(player, M.CREW_SUPPLY_PRODUCT)
	end
end

local function grantSupplyDrop(buyer: Player)
	local crew = buyer:GetAttribute("Crew") or 1
	for _, mate in CrewService.members(crew) do
		mate:SetAttribute("Run_energydrink", true)
		mate:SetAttribute("Run_softboots", true)
		Remotes.Notify:FireClient(mate, `{buyer.DisplayName} sent the crew a supply drop: energy drink and soft boots for the next run.`, "money")
	end
end

function MonetisationService.enabled(): boolean
	return M.SUIT_COLOURS_PASS ~= 0 or M.SUPPORTER_PASS ~= 0 or M.CREW_SUPPLY_PRODUCT ~= 0
end

function MonetisationService.init()
	Players.PlayerAdded:Connect(function(p)
		task.spawn(refreshPasses, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(refreshPasses, p)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and (passId == M.SUIT_COLOURS_PASS or passId == M.SUPPORTER_PASS) then
			refreshPasses(player)
			if player.Character then
				player:LoadCharacter()
			end
		end
	end)
	if M.CREW_SUPPLY_PRODUCT ~= 0 then
		MarketplaceService.ProcessReceipt = function(receipt)
			local buyer = Players:GetPlayerByUserId(receipt.PlayerId)
			if not buyer then
				return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries when they're back
			end
			if receipt.ProductId == M.CREW_SUPPLY_PRODUCT then
				grantSupplyDrop(buyer)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
end

return MonetisationService
