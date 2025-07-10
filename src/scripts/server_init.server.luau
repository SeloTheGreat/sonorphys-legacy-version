local server = require("../server")
local rep = require("../_replication")

do
	local remote = Instance.new("RemoteEvent")
	remote.Name = "Replication"
	remote.Parent = script.Parent.Parent._replication
	rep.ReplicationEvent = remote
end

server.init()