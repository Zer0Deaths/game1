-- Shared code lives here. Both the server and the client can require it.
local Hello = {}

function Hello.greet(who: string): string
	return `Hello from {who}! Rojo sync is working.`
end

return Hello
