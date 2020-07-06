DownloadDialog = DownloadDialog or class(MenuDialog)
DownloadDialog.type_name = "DownloadDialog"
function DownloadDialog:init(params, menu)
    if self.type_name == DownloadDialog.type_name then
        params = params and clone(params) or {}
    end
    DownloadDialog.super.init(self, table.merge(params, {
        offset = 8,
        auto_height = true,
        size = 20,
    }), menu)
end

function DownloadDialog:_Show(params)
	table.merge(params, {
        no = params.no or managers.localization:text("beardlib_close"),
        yes = false,
	})
    if not InputDialog.super._Show(self, params) then
        return
    end
    local color = self._menu.backgrond_color or Color.white
    self._progress = self._menu:Panel():rect({
        name = "DownloadProgress",
        color = color:contrast():with_alpha(0.25),
        halign ="grow",
        valign ="grow",
        w = 0,
    })
    self._status = self._menu:Divider({
        name = "Status",
        text = "",
        index = params.title and "After|Title" or 1,
        text_align = "center",
        text_vertical = "center",
    })
    self._menu:GetItem("No"):SetEnabled(false)
    if params.create_items then
        params.create_items(self._menu)
    end
    self:show_dialog()
    self:SetStatus("beardlib_waiting")
end

function DownloadDialog:SetInstalling()
    self:SetStatus("beardlib_download_complete")
end

function DownloadDialog:SetFailed()
    self:SetStatus("beardlib_download_failed")
    self._menu:GetItem("No"):SetEnabled(true)
    self._allowed_to_cancel = true
end

function DownloadDialog:SetFinished()
    self:SetStatus("beardlib_done")
    self._menu:GetItem("No"):SetEnabled(true)
    self._allowed_to_cancel = true
    self:hide()
end

function DownloadDialog:SetStatus(status, not_localized)
    self._status:SetText(not_localized and status or managers.localization:text(status))
end

function DownloadDialog:SetProgress(id, bytes, total_bytes)
    if not alive(self._progress) then
        return
    end
    local progress = bytes / total_bytes
    local mb = bytes / (1024 ^ 2)
    local total_mb = total_bytes / (1024 ^ 2)
    self:SetStatus(string.format(managers.localization:text("beardlib_downloading").."%.2f/%.2fmb(%.0f%%)", mb, total_mb, tostring(progress * 100)), true)
    self._progress:set_w(self._menu:Panel():w() * progress)
end

function DownloadDialog:hide(...)
    if not self._allowed_to_cancel then
        return
    end
    return self.super.hide(self, ...)
end