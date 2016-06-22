for _, Name in pairs(BeardLib.custom_mission_elements) do
    dofile(BeardLib.ClassDirectory .. "Elements/Element" .. Name .. ".lua")
end
