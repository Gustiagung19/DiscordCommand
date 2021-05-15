local lastdata = nil
ESX = nil

function DiscordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest("https://discordapp.com/api/" .. endpoint,
                       function(errorCode, resultData, resultHeaders)
        data = {data = resultData, code = errorCode, headers = resultHeaders}
    end, method, #jsondata > 0 and json.encode(jsondata) or "", {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. Config.BotToken
    })
    while data == nil do Citizen.Wait(0) end
    return data
end

function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function mysplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function GetRealPlayerName(playerId)
    if Config.ESX then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        return xPlayer.getName()
    else
        return "ESX TIDAK DIAKTIFKAN"
    end
end

function ExecuteCOMM(command)
    if string.starts(command, Config.Prefix) then
        -- Get Player Count
        if string.starts(command, Config.Prefix .. "playercount") then
            sendToDiscord("Player Counts", "Pemain Saat Ini Di Server : " ..
                              GetNumPlayerIndices(), 16711680)
            -- Kick Someone
        elseif string.starts(command, Config.Prefix .. "kick") then
            local t = mysplit(command, " ")
            if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                sendToDiscord("KICKED Succesfully",
                              "Berhasil Kick " .. GetPlayerName(t[2]),
                              16711680)
                DropPlayer(t[2], "Anda Telah Di Kick")
            else
                sendToDiscord("Could Not Find",
                              "Tidak Dapat Menemukan ID, Pastikan Untuk Memasukkan ID Yang Valid",
                              16711680)
            end

            -- slay
        elseif string.starts(command, Config.Prefix .. "slay") then
            local t = mysplit(command, " ")
            if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                TriggerClientEvent("discordc:kill", t[2])
                TriggerEvent('chat:addMessage', t[2], {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {
                        "NOTIFIKASI :",
                        "^1 Anda Telah Dibunuh"
                    }
                })
                sendToDiscord("KILLED Succesfully",
                              "Berhasil Dibunuh " .. GetPlayerName(t[2]),
                              16711680)
            else
                sendToDiscord("Could Not Find",
                              "Tidak Dapat Menemukan ID, Pastikan Untuk Memasukkan ID Yang Valid",
                              16711680)
            end

            -- revive
        elseif string.starts(command, Config.Prefix .. "revive") then
            if Config.ESX then
                local t = mysplit(command, " ")
                if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                    TriggerClientEvent("esx_ambulancejob:revive", t[2])
                    sendToDiscord("Revived Succesfully",
                                  "Berhasil Revive " .. GetPlayerName(t[2]),
                                  16711680)
                else
                    sendToDiscord("Could Not Find",
                                  "Tidak Dapat Menemukan ID, Pastikan Untuk Memasukkan ID Yang Valid",
                                  16711680)
                end
            else
                sendToDiscord("Discord BOT", "ESX Tidak Diaktifkan", 16711680)
            end

            -- notific
        elseif string.starts(command, Config.Prefix .. "notific") then
            local safecom = command
            local t = mysplit(command, " ")
            if t[2] ~= nil and GetPlayerName(t[2]) ~= nil and t[3] ~= nil then
                TriggerClientEvent('chat:addMessage', t[2], {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {
                        "NOTIFIKASI :",
                        "^1 " ..
                            string.gsub(safecom, "!notific " .. t[2] .. " ", "")
                    }
                })
                sendToDiscord("Sended Succesfully",
                              "Berhasil Dikirim " ..
                                  string.gsub(safecom,
                                              "!notific " .. t[2] .. " ", "") ..
                                  " Untuk " .. GetPlayerName(t[2]), 16711680)
            else
                sendToDiscord("Could Not Find", "Tidak Valid", 16711680)
            end

            -- announce
        elseif string.starts(command, Config.Prefix .. "announce") then
            local safecom = command
            local t = mysplit(command, " ")
            if t[2] ~= nil then
                TriggerClientEvent('chat:addMessage', -1, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {
                        "PENGUMUMAN :",
                        "^1 " ..
                            string.gsub(safecom, Config.Prefix .. "announce", "")
                    }
                })
                sendToDiscord("Berhasil Dikirim",
                              "Berhasil Dikirim : " ..
                                  string.gsub(safecom,
                                              Config.Prefix .. "announce", "") ..
                                  " | Untuk " .. GetNumPlayerIndices() ..
                                  " Pemain Di Server", 16711680)
            else
                sendToDiscord("Could Not Find", "Tidak Valid", 16711680)
            end
            -- Perintah Tidak Ditemukan
        else
            sendToDiscord("Discord Command",
                          "Perintah Tidak Ditemukan, Harap Pastikan Anda Memasukkan Perintah Yang Valid",
                          16711680)
        end
    end
end

Citizen.CreateThread(function()
    sendToDiscord('Discord Command','Discord Command Bot Sekarang Online',16711680)
    while true do
        local chanel =
            DiscordRequest("GET", "channels/" .. Config.ChannelID, {})
        if chanel.data then
            local data = json.decode(chanel.data)
            local lst = data.last_message_id
            local lastmessage = DiscordRequest("GET", "channels/" ..
                                                   Config.ChannelID ..
                                                   "/messages/" .. lst, {})
            if lastmessage.data then
                local lstdata = json.decode(lastmessage.data)
                if lastdata == nil then lastdata = lstdata.id end
                if lastdata ~= lstdata.id and lstdata.author.username ~=
                    Config.ReplyUserName then
                    ExecuteCOMM(lstdata.content)
                    lastdata = lstdata.id
                end
            end
        end
        Citizen.Wait(Config.WaitEveryTick)
    end
end)

function sendToDiscord(name, message, color)
    local connect = {
        {
            ["color"] = color,
            ["title"] = "**" .. name .. "**",
            ["description"] = message,
            ["footer"] = {["text"] = "Developed By Gusti Agung#9357"}
        }
    }
    PerformHttpRequest(Config.WebHook, function(err, text, headers) end, 'POST',
                       json.encode({
        username = Config.ReplyUserName,
        embeds = connect,
        avatar_url = Config.AvatarURL
    }), {['Content-Type'] = 'application/json'})
end