local orig_TradeManager_save = TradeManager.save

function TradeManager:save(save_data)
    orig_TradeManager_save(self, save_data)
    if save_data and save_data.trade and save_data.trade.outfits then
        for i, data in pairs(save_data.trade.outfits) do
            data.outfit = BeardLib.Utils:CleanOutfitString(data.outfit)
        end
    end
end
