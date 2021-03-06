--[[
	Switching Service
]]--

local Delta = ...

IPlib = Delta.lib.Address

local function wrap(side)
	if peripheral.isPresent(side) then
		if peripheral.getType(side) == "modem" then
			if peripheral.call(side,"isWireless") == false then
				print("Accepted ", side)
				return Delta.modem(side)
			end
		end
	end
	return nil
end

local function Switch()
	local MainSide
	local MainIP
	local private_network_ID
	local modems = {
		top = wrap("top"),
		bottom = wrap("bottom"),
		front = wrap("front"),
		back = wrap("back"),
		right = wrap("right"),
		left = wrap("left"),
	}

	for i,v in pairs(modems) do
		istrue = v.connect()
		if istrue then
			print("Is true ", i)
			MainSide = i
			MainIP = v.IP
		end
		v.open(65535)
		v.open(65534)
		v.open(64511)
	end

	for i,v in pairs(modems) do
		v.setIP(MainIP)
	end
	print(MainIP)

	local ips = {

	}
	local macs = {

	}
	
	local side, protocol, req_id, message, s_side, d_ip, s_ip

	while true do
		event = {coroutine.yield("modem_message")}
		if event[1] == "modem_message" then
			side, protocol, req_id, message = event[2], event[3], event[4], event[5]
			if protocol == 65535 then
				if not (side == MainSide) then
					modems[MainSide].transmit(65535, req_id, message)
					print("Protocol 65535...")
					macs[message] = side
				end
			elseif protocol == 65534 then
				if side == MainSide then
					s_side = macs[message[1]]
					if s_side then
						modems[s_side].transmit(65534, req_id, message)
						macs[message[1]] = nil
						ips[message[2]] = side
						print("Protocol 65534...")
					end
				end
			elseif protocol == 64511 then
				d_ip, s_ip = message[1], message[2]
				ips[s_ip] = side
				message[6] = message[6] - 1

				--[[Private Network Stuff]]--
				private_network_ID = nil
				private_network_ID = IPlib.isReserved(d_ip, true)

				if private_network_ID then
					if private_network_ID == 9 then
						s_side = ips[sip]
						if s_side then
							modems[s_side].transmit(64511, 0x0, message)
							print("Protocol 64511...")
						else
							for i,v in pairs(modems) do
								if i ~= side then
									v.transmit(64511, 0x0, message)
								end
							end
							print("Protocol 64511...") --wow
						end
					end
				else
					modems[MainSide].transmit(64511, 0x0, message)
					print("Protocol 64511...") --wow
					print("Main side")
				end
			end
		end
	end
end

return Switch 