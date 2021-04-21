import "base/native/LuaInterface_001" for LuaInterface
import "base/native" for Logger
import "base/native/DB_001" for DBManager

class AssetLoader {
    loaded { _loaded }
    loaded = (value) { 
        _loaded = value 
    }
    
    construct new() {
        loaded = {}
    }

    load(ext, path) {
        if (!this.loaded.containsKey(ext)) {
            this.loaded[ext] = {}
        }
        if (!this.loaded[ext][path]) {
            this.loaded[ext][path] = true
            var hook = DBManager.register_asset_hook(path, ext)
            hook.fallback = true
            hook.set_direct_bundle(path, ext)
            //Logger.log("Hello, loading %(path).%(ext)")
        }
        return true
    }
}

LuaInterface.register_object("AssetLoader", AssetLoader.new())
