for _, name in ipairs(BeardLib.config.mission_elements) do 
    dofile(BeardLib.config.classes_dir .. "Elements/Element" .. name .. ".lua") 
end