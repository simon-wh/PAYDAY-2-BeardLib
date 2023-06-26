--- Example: <AssetUpdates provider="modworkshop" version="1.0" id="12345"/> with ID being the ID in the mod page URL. 
--- Version belongs to the mod.
ModAssetsModule._providers.modworkshop = {
    version_api_url = "https://api.modworkshop.net/mods/$id$/version",
    download_url = "https://api.modworkshop.net/mods/$id$/download",
    page_url = "https://modworkshop.net/mod/$id$"
}

--- Example: <AssetUpdates provider="modworkshop_file" id="123" version="1.0" mod_id="12345"/> with ID being the file ID in the site.
--- Version belongs to the file.
ModAssetsModule._providers.modworkshop_file = {
    version_api_url = "https://api.modworkshop.net/files/$id$/version",
    download_url = "https://api.modworkshop.net/files/$id$/download",
    page_url = "https://modworkshop.net/mod/$mod_id$"
}

--support for old mods
ModAssetsModule._providers.lastbullet = clone(ModAssetsModule._providers.modworkshop)