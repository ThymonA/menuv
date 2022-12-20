--Example of line to put : MenuV.SubTitle("Press [E] to access the Store", 1)
function MenuV.SubTitle(text, time)
    ClearPrints()
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(time and math.ceil(time) or 0, true)
end