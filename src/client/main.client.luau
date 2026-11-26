-- Runs on each player's device. Synced to StarterPlayerScripts.Client.main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.greet(Players.LocalPlayer.Name .. "'s client"))
