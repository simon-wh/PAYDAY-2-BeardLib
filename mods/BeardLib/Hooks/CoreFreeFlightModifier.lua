core:module("CoreFreeFlightModifier")
FreeFlightModifier = FreeFlightModifier or CoreFreeFlightModifier.FreeFlightModifier

InfiniteFreeFlightModifier = InfiniteFreeFlightModifier or class(FreeFlightModifier)

function InfiniteFreeFlightModifier:init(name, value, increment, callback)
	self._name = assert(name)
	self._value = assert(value)
	self._increment = assert(increment)
	self._callback = callback
end
function InfiniteFreeFlightModifier:step_up()
	self._value = self._value + self._increment
	if self._callback then
		self._callback(self:value())
	end
end
function InfiniteFreeFlightModifier:step_down()
	self._value = self._value - self._increment
	if self._callback then
		self._callback(self:value())
	end
end
function InfiniteFreeFlightModifier:name_value()
	return string.format("%10.10s %7.2f", self._name, self._value)
end
function InfiniteFreeFlightModifier:value()
	return self._value
end
function InfiniteFreeFlightModifier:set_value(new_value)
	self._value = assert(new_value)
end