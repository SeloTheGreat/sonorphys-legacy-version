--Disconnects and clears a connection table
return function(t: {RBXScriptConnection})
	for i, v in pairs(t) do
		v:Disconnect()
	end
	table.clear(t)
end
