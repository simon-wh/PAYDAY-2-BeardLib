_G.ModManager = {}
local mm = ModManager

function mm:RegisterHook(source_file, path, file, type, mod)
    path = path .. "/"
    local hook_file = BeardLib.Utils.Path:Combine(path, file)
    local dest_tbl = type == "pre" and (_prehooks or (BLT and BLT.hook_tables.pre)) or (_posthooks or (BLT and BLT.hook_tables.post))
    if dest_tbl and FileIO:Exists(hook_file) then
        local req_script = source_file:lower()

        dest_tbl[req_script] = dest_tbl[req_script] or {}
        table.insert(dest_tbl[req_script], {
            mod_path = path,
            mod = mod,
            script = file
        })
    else
        BeardLib:log("[ERROR] Hook file not readable by the lua state! File: %s", file)
    end
end

function mm:RegisterKeybind() end
function mm:RegisterLibrary() end