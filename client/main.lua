local QBCore = exports['qb-core']:GetCoreObject()

local holdingUp = false
local store = ''
local blipRobbery = nil

function DrawTxt(x,y, width, height, scale, text, r, g, b, a, outline)
	SetTextFont(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropshadow(0, 0, 0, 0,255)
	SetTextDropShadow()
	if outline then
        SetTextOutline()
    end
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x - width / 2, y - height / 2 + 0.005)
end

RegisterNetEvent('qb_holdup:currentlyRobbing', function(currentStore)
	holdingUp, store = true, currentStore
end)

RegisterNetEvent('qb_holdup:killBlip', function()
	RemoveBlip(blipRobbery)
end)

RegisterNetEvent('qb_holdup:setBlip', function(position)
	blipRobbery = AddBlipForCoord(position)
	SetBlipSprite(blipRobbery, 161)
	SetBlipScale(blipRobbery, 2.0)
	SetBlipColour(blipRobbery, 3)
	PulseBlip(blipRobbery)
end)

RegisterNetEvent('qb_holdup:tooFar', function()
	holdingUp, store = false, ''
    QBCore.Functions.Notify(Config.Translate[Config.Language]["robbery_cancelled"], 'error', 7500)
end)

RegisterNetEvent('qb_holdup:robberyComplete', function(award)
	holdingUp, store = false, ''
    QBCore.Functions.Notify(Config.Translate[Config.Language]["robbery_complete"]..award, 'success', 7500)
end)

RegisterNetEvent('qb_holdup:startTimer', function()
	local timer = Stores[store].secondsRemaining
	CreateThread(function()
		while timer > 0 and holdingUp do
			Wait(1000)
			if timer > 0 then
				timer = timer - 1
			end
		end
	end)
	CreateThread(function()
		while holdingUp do
			Wait(0)
			DrawTxt(0.66, 1.44, 0.6, 1.0, 0.4, Config.Translate[Config.Language]["robbery_timer"] .. timer, 255, 255, 255, 255)
		end
	end)
end)

CreateThread(function()
	for k,v in pairs(Stores) do
		local blip = AddBlipForCoord(v.position)
		SetBlipSprite(blip, 156)
		SetBlipScale(blip, 0.8)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(Config.Translate[Config.Language]["shop_robbery"])
		EndTextCommandSetBlipName(blip)
	end
end)

CreateThread(function()
	while true do
		Wait(1)
		local playerPos = GetEntityCoords(PlayerPedId())
		local letSleep = true

		for k,v in pairs(Stores) do
			local distance = #(playerPos - v.position)

			if distance < Config.Marker.DrawDistance then
				if not holdingUp then
                    letSleep = false
					DrawMarker(Config.Marker.Type, v.position, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, false, false, false, false)
					if distance < 2.0 then
						exports['qb-core']:DrawText(Config.Translate[Config.Language]["press_to_rob"], 'left')
						if IsControlJustReleased(0, 38) then
							if IsPedArmed(PlayerPedId(), 4) then
								TriggerServerEvent('qb_holdup:robberyStarted', k)
							else
								QBCore.Functions.Notify(Config.Translate[Config.Language]["no_threat"], 'success', 7500)
							end
							Wait(2000)
							exports['qb-core']:HideText()
						end
					else
                        exports['qb-core']:HideText()
					end
				end
                break
			end
		end
		
		if holdingUp then
            letSleep = false
			if #(playerPos - Stores[store].position) > Config.MaxDistance then
				TriggerServerEvent('qb_holdup:tooFar', store)
			end
		end
        if letSleep then
            Wait(1500)
        end
	end
end)