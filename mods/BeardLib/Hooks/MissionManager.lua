for _, Name in pairs(BeardLib.custom_mission_elements) do
    dofile(BeardLib.config.classes_dir .. "Elements/Element" .. Name .. ".lua")
end
