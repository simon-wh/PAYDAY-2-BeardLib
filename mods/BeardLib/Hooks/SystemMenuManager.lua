core:module("SystemMenuManager")
require("lib/managers/dialogs/keyboardinputdialog")

GenericSystemMenuManager = GenericSystemMenuManager or SystemMenuManager.GenericSystemMenuManager

function GenericSystemMenuManager:show_keyboard_input(data)
    self.KEYBOARD_INPUT_DIALOG = self.KEYBOARD_INPUT_DIALOG or KeyboardInputDialog
	self:_show_class(data, self.GENERIC_KEYBOARD_INPUT_DIALOG, self.KEYBOARD_INPUT_DIALOG, false)
end