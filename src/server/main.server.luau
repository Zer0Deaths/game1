-- Runs on the server. Synced to ServerScriptService.Server.main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.greet("the server"))
