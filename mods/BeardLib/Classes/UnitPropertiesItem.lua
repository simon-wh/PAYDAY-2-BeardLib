core:import("CoreMenuItem")
log("UnitPropertiesItem")
UnitPropertiesItem = UnitPropertiesItem or class(CoreMenuItem.Item)
UnitPropertiesItem.TYPE = "unit_properties"

function UnitPropertiesItem:init(data_node, parameters)
	UnitPropertiesItem.super.init(self, data_node, parameters)
	self._type = UnitPropertiesItem.TYPE
end
