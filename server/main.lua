local QBCore = exports['qb-core']:GetCoreObject()

local rob = false
local robbers = {}
TimeoutCount = -1
CancelledTimeouts = {}

RegisterNetEvent('qb_holdup:tooFar', function(currentStore)
	local source = source
	local xPlayers = QBCore.Functions.GetPlayers()
	rob = false

	for i = 1, #xPlayers do
		local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
		
		if (xPlayer.PlayerData.job.name == "police" or xPlayer.PlayerData.job.type == "leo") and xPlayer.PlayerData.job.onduty then
			TriggerClientEvent('qb_holdup:killBlip', xPlayers[i])
		end
	end
	
	if robbers[source] then
		TriggerClientEvent('qb_holdup:tooFar', source)
		clearTimeout(robbers[source])
        robbers[source] = nil
	end
end)

RegisterNetEvent('qb_holdup:robberyStarted', function(currentStore)
	local source  = source
	local xPlayer  = QBCore.Functions.GetPlayer(source)
	if Stores[currentStore] then
		local store = Stores[currentStore]
		if (os.time() - store.lastRobbed) < Config.TimerBeforeNewRob and store.lastRobbed ~= 0 then
			TriggerClientEvent('QBCore:Notify', source, Config.Translate[Config.Language]["recently_robbed"].. Config.TimerBeforeNewRob - (os.time() - store.lastRobbed), 'error', 5000)
			return
		end
		if not rob then
			local Cops = QBCore.Functions.GetDutyCount('police')

			if Cops >= Config.PoliceNumberRequired then
				local xPlayers = QBCore.Functions.GetPlayers()
				
				rob = true
				for i = 1, #xPlayers do
					local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
					if (xPlayer.PlayerData.job.name == "police" or xPlayer.PlayerData.job.type == "leo") and xPlayer.PlayerData.job.onduty then
						TriggerClientEvent('qb_holdup:setBlip', xPlayers[i], Stores[currentStore].position)
					end
				end

                TriggerClientEvent('QBCore:Notify', source, Config.Translate[Config.Language]["started_to_rob"], 'success', 5000)
                TriggerClientEvent('QBCore:Notify', source, Config.Translate[Config.Language]["alarm_triggered"], 'success', 5000)
				TriggerClientEvent('qb_holdup:currentlyRobbing', source, currentStore)
				TriggerClientEvent('qb_holdup:startTimer', source)
				Stores[currentStore].lastRobbed = os.time()
				robbers[source] = setTimeout(store.secondsRemaining * 1000, function()
					rob = false
                    if xPlayer then
                        TriggerClientEvent('qb_holdup:robberyComplete', source, store.reward)
                        
						if Config.GiveBlackMoney then
							local reward = store.reward
	
							for i, v in pairs(xPlayer.PlayerData.items) do
								if v.name == 'markedbills' then
									xPlayer.Functions.RemoveItem('markedbills', 1)
									if v.info and v.info.worth then
										reward = reward + v.info.worth
									elseif v.metadata and v.metadata.worth then
										reward = reward + v.metadata.worth
									end
									break
								end
							end
							xPlayer.Functions.AddItem('markedbills', 1, false, {worth = reward})
						else
							xPlayer.Functions.AddMoney('cash', store.reward)
						end

                        for i = 1, #xPlayers do
							local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
							if (xPlayer.PlayerData.job.name == "police" or xPlayer.PlayerData.job.type == "leo") and xPlayer.PlayerData.job.onduty then
                            	TriggerClientEvent('qb_holdup:killBlip', xPlayers[i])
							end
                        end
                    end
				end)
			else
				TriggerClientEvent('QBCore:Notify', source, Config.Translate[Config.Language]["min_police"], 'error', 7500)
			end
		else
            TriggerClientEvent('QBCore:Notify', source, Config.Translate[Config.Language]["robbery_already"], 'success', 5000)
		end
	end
end)

setTimeout = function(msec, cb)
    local id = TimeoutCount + 1
    SetTimeout(msec, function()
        if CancelledTimeouts[id] then
            CancelledTimeouts[id] = nil
        else
            cb()
        end
    end)
    TimeoutCount = id
    return id
end

clearTimeout = function(id)
    CancelledTimeouts[id] = true
end