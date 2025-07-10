local Players = game:GetService("Players")

local types = require("./types")

local serdes = {}
serdes.ReplicationEvent = nil :: RemoteEvent?

--not yield safe
serdes.server_callback = function()end :: (sentFrom: Player, pack: types.ReplicationPacket) -> ()
--yield safe due to receive doing nothing
serdes.client_callback = serdes.server_callback :: (sender: Player, pack: types.ReplicationPacket) -> ()

function serdes.uni_encode(hum: Humanoid): buffer
	--unsigned int 8 : 1 byte
	--float 32 : 4 bytes
	--instance : 5 bytes
	local b = buffer.create(1 + 4)
	buffer.writeu8(b, 0, hum:GetState().Value)
	buffer.writef32(b, 1, hum.Health)
	return b
end

function serdes.uni_decode(b: buffer): types.ReplicationPacket
	return {
		State = Enum.HumanoidStateType:FromValue(buffer.readu8(b, 0)),
		Health = buffer.readf32(b, 1)
	}
end

--Replicates to ever other player
function serdes.server_receive(sentFrom: Player, b: buffer)
	for i, v in ipairs(Players:GetPlayers()) do
		if v == sentFrom then continue end
		serdes.ReplicationEvent:FireClient(v, sentFrom, b)
	end
	serdes.server_callback(sentFrom, serdes.uni_decode(b))
end

--Currently doesn't do anything other than call the client callback
function serdes.client_receive(sender: Player, b: buffer)
	serdes.client_callback(sender, serdes.uni_decode(b))
end

return serdes