local function view(data, config, units, event, gpsDegMin, getTelemetryId, getTelemetryUnit, FILE_PATH, SMLCD, FLASH, PREV, INCR, NEXT, DECR, HORUS)

	local CONFIG_X = HORUS and 90 or (SMLCD and 0 or 46)
	local TOP = HORUS and 37 or 11
	local LINE = HORUS and 22 or 9
	local RIGHT = HORUS and 200 or 83
	local GPS = HORUS and 45 or 21
	local ROWS = HORUS and 9 or 5
	local FONT = HORUS and 0 or SMLSIZE

	-- Config options: o=display Order / t=Text / c=Characters / v=default Value / l=Lookup text / d=Decimal / m=Min / x=maX / i=Increment / a=Append text / b=Blocked by
	local config2 = {
		{ t = "Battery View",     i = 1, l = {[0] = "Cell", "Total"} },
		{ t = "Cell Low",         m = 2.7, i = 0.1, a = "V", b = 2 },
		{ t = "Cell Critical",    m = 2.6, i = 0.1, a = "V", b = 2 },
		{ t = "Voice Alerts",     i = 1, l = {[0] = "Off", "Critical", "All"} },
		{ t = "Feedback",         i = 1, l = {[0] = "Off", "Haptic", "Beeper", "All"} },
		{ t = "Max Altitude",     i = data.alt_unit == 10 and 10 or 1, a = units[data.alt_unit], b = 10 },
		{ t = "Variometer",       i = 1, l = {[0] = "Off", "Graph", "Voice", "Both"} },
		{ t = "RTH Feedback",     i = 1, l = {[0] = "Off", "On"}, b = 18 },
		{ t = "HeadFree Feedback",i = 1, l = {[0] = "Off", "On"}, b = 18 },
		{ t = "RSSI Feedback",    i = 1, l = {[0] = "Off", "On"}, b = 18 },
		{ t = "Battery Alerts",   i = 1, l = {[0] = "Off", "Critical", "All"} },
		{ t = "Altitude Alert",   i = 1, l = {[0] = "Off", "On"} },
		{ t = "Timer",            i = 1, l = {[0] = "Off", "Auto", "Timer1", "Timer2"} },
		{ t = "Rx Voltage",       i = 1, l = {[0] = "Off", "On"} },
		{ t = "GPS",              i = 0, l = {[0] = data.gpsLatLon} },
		{ t = "GPS Coordinates",  i = 1, l = {[0] = "Decimal", "Deg/Min"} },
		{ t = "Fuel Critical",    m = 1, i = 1, a = "%", b = 2 },
		{ t = "Fuel Low",         m = 2, i = 1, a = "%", b = 2 },
		{ t = "Tx Voltage",       i = 1, l = {[0] = "Number", "Graph", "Both"} },
		{ t = "Speed Sensor",     i = 1, l = {[0] = "GPS", "Pitot"} },
		{ t = "GPS Warning",      m = 1.0, i = 0.5, a = " HDOP" },
		{ t = "GPS HDOP View",    i = 1, l = {[0] = "Graph", "Decimal"} },
		{ t = "Fuel Unit",        i = 1, l = {[0] = "Percent", "mAh", "mWh"} },
		{ t = "Vario Steps",      m = 0, i = 1, a = units[data.alt_unit], l = {[0] = 1, 2, 5, 10, 15, 20, 25, 30, 40, 50} },
		{ t = "View Mode",        i = 1, l = {[0] = "Classic", "Pilot", "Radar", "Altitude"} },
		{ t = "AltHold Center FB",i = 1, l = {[0] = "Off", "On"}, b = 18 },
		{ t = "Battery Capacity", m = 150, i = 50, a = "mAh" },
		{ t = "Altitude Graph",   i = 1, l = {[0] = "Off", 1, 2, 3, 4, 5, 6}, a = " Min" },
		{ t = "Cell Calculation", m = 4.2, i = 0.1, a = "V" },
		{ t = "Aircraft symbol",  i = 1, l = {[0] = "Boeing", "Classic", "Garmin1", "Garmin2", "Dynon", "Water"} },
		{ t = "Radar home",       i = 1, l = {[0] = "Adjust", "Center"} },
		{ t = "Orientation",      i = 1, l = {[0] = "Launch", "Compass"} },
	}

	if data.lang ~= "en" then
		local modes, labels
		local tmp = FILE_PATH .. "lang_" .. data.lang .. ".luac"
		local fh = io.open(tmp)
		if fh ~= nil then
			io.close(fh)
			loadfile(tmp)(modes, labels, config2, true)
			collectgarbage()
		end
	end
		
	local function saveConfig()
		local fh = io.open(FILE_PATH .. "cfg/" .. model.getInfo().name .. ".dat", "w")
		if fh == nil then
			data.msg = "Folder iNav/cfg missing"
			data.startup = 1
		else
			for line = 1, #config do
				if config[line].d == nil then
					io.write(fh, string.format("%0" .. config[line].c .. "d", config[line].v))
				else 
					io.write(fh, math.floor(config[line].v * 10))
				end
			end
			io.close(fh)
		end
	end

	if HORUS then
		lcd.setColor(CUSTOM_COLOR, GREY)
		lcd.drawFilledRectangle(CONFIG_X - 10, TOP - 7, LCD_W - CONFIG_X * 2 + 20, LINE * (ROWS + 1) + 12, CUSTOM_COLOR)
	end
	if not SMLCD then
		lcd.drawRectangle(CONFIG_X - (HORUS and 10 or 3), TOP - (HORUS and 7 or 2), LCD_W - CONFIG_X * 2 + (HORUS and 20 or 6), LINE * (ROWS + 1) + (HORUS and 12 or 1), SOLID)
	end

	-- Disabled options
	for line = 1, #config do
		local z = config[line].z
		config2[z].p = (config2[z].b ~= nil and config[config[config2[z].b].z].v == 0) and 1 or nil
	end

	-- Special disabled option and limit cases
	config2[7].p = data.crsf and 1 or (data.vspeed_id == -1 and 1 or nil)
	config2[22].p = data.crsf and 1 or (HORUS and 1 or nil)
	config2[25].p = HORUS and 1 or nil
	if config2[17].p == nil then
		config2[17].p = (not data.showCurr or config[23].v ~= 0) and 1 or nil
		config2[18].p = config2[17].p
	end
	config[19].x = config[14].v == 0 and 2 or SMLCD and 1 or 2
	config[25].x = config[28].v == 0 and 2 or 3
	if config[28].v == 0 and config[25].v == 3 then
		config[25].v = 2
	end
	config[19].v = math.min(config[19].x, config[19].v)
	config2[24].p = data.crsf and 1 or (config[7].v < 2 and 1 or nil)
	config2[20].p = not data.pitot and 1 or nil
	config2[23].p = not data.showFuel and 1 or nil
	config2[27].p = (not data.crsf or config[23].v > 0) and 1 or nil
	if data.crsf then
		config2[9].p = 1
		config2[14].p = 1
		config2[21].p = 1
	end
	config2[30].p = HORUS ~= true and 1 or nil
	config2[31].p = HORUS ~= true and 1 or nil

	for line = data.configTop, math.min(#config, data.configTop + ROWS) do
		local y = (line - data.configTop) * LINE + TOP
		local z = config[line].z
		local tmp = (data.configStatus == line and INVERS + data.configSelect or 0) + (config[z].d ~= nil and PREC1 or 0)
		if not data.showCurr and z >= 17 and z <= 18 then
			config2[z].p = 1
		end
		lcd.drawText(CONFIG_X, y, config2[z].t, FONT)
		if config2[z].p == nil then
			if config2[z].l == nil then
				lcd.drawText(CONFIG_X + RIGHT, y, (config[z].d ~= nil and string.format("%.1f", config[z].v) or config[z].v) .. config2[z].a, FONT + tmp)
			else
				if not config2[z].l then
					lcd.drawText(CONFIG_X + RIGHT, y, config[z].v, FONT + tmp)
				else
					if z == 15 then
						lcd.drawText(CONFIG_X + GPS, y, config[16].v == 0 and string.format("%10.6f %11.6f", config2[z].l[config[z].v].lat, config2[z].l[config[z].v].lon) or " " .. gpsDegMin(config2[z].l[config[z].v].lat, true) .. "  " .. gpsDegMin(config2[z].l[config[z].v].lon, false), FONT + tmp)
					else
						lcd.drawText(CONFIG_X + RIGHT, y, config2[z].l[config[z].v] .. ((config2[z].a == nil or config[z].v == 0) and "" or config2[z].a), FONT + tmp)
					end
				end
			end
		else
			lcd.drawText(CONFIG_X + RIGHT, y, "--", FONT + tmp)
		end
	end

	if data.configSelect == 0 then
		-- Select config option
		if event == EVT_EXIT_BREAK then
			saveConfig()
			data.configLast = data.configStatus
			data.configStatus = 0
		elseif event == NEXT or event == EVT_DOWN_REPT or event == EVT_MINUS_REPT then -- Next option
			data.configStatus = data.configStatus == #config and 1 or data.configStatus + 1
			data.configTop = data.configStatus > math.min(#config, data.configTop + ROWS) and data.configTop + 1 or (data.configStatus == 1 and 1 or data.configTop)
			while config2[config[data.configStatus].z].p ~= nil do
				data.configStatus = math.min(data.configStatus + 1, #config)
				data.configTop = data.configStatus > math.min(#config, data.configTop + ROWS) and data.configTop + 1 or data.configTop
			end
		elseif event == PREV or event == EVT_UP_REPT or event == EVT_PLUS_REPT then -- Previous option
			data.configStatus = data.configStatus == 1 and #config or data.configStatus - 1
			data.configTop = data.configStatus < data.configTop and data.configTop - 1 or (data.configStatus == #config and #config - ROWS or data.configTop)
			while config2[config[data.configStatus].z].p ~= nil do
				data.configStatus = math.max(data.configStatus - 1, 1)
				data.configTop = data.configStatus < data.configTop and data.configTop - 1 or data.configTop
			end
		end
	else
		local z = config[data.configStatus].z
		if event == EVT_EXIT_BREAK then
			data.configSelect = 0
		elseif event == INCR or event == EVT_UP_REPT or event == EVT_PLUS_REPT then
			config[z].v = math.min(math.floor(config[z].v * 10 + config2[z].i * 10) / 10, config[z].x == nil and 1 or config[z].x)
		elseif event == DECR or event == EVT_DOWN_REPT or event == EVT_MINUS_REPT then
			config[z].v = math.max(math.floor(config[z].v * 10 - config2[z].i * 10) / 10, config2[z].m == nil and 0 or config2[z].m)
		end

		-- Special cases
		if event then
			if z == 2 then -- Cell low > critical
				config[2].v = math.max(config[2].v, config[3].v + 0.1)
			elseif z == 3 then -- Cell critical < low
				config[3].v = math.min(config[3].v, config[2].v - 0.1)
			elseif z == 18 then -- Fuel low > critical
				config[18].v = math.max(config[18].v, config[17].v + 1)
			elseif z == 17 then -- Fuel critical < low
				config[17].v = math.min(config[17].v, config[18].v - 1)
			elseif z == 20 then -- Speed sensor
				local tmp = config[20].v == 0 and "GSpd" or "ASpd"
				data.speed_id = getTelemetryId(tmp)
				data.speedMax_id = getTelemetryId(tmp .. "+")
				data.speed_unit = getTelemetryUnit(tmp)
			elseif z == 28 then -- Altitude graph
				data.alt = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
			elseif config2[z].i > 1 then
				config[z].v = math.floor(config[z].v / config2[z].i) * config2[z].i
			end
		end
	end

	if event == EVT_ENTER_BREAK then
		data.configSelect = (data.configSelect == 0) and BLINK or 0
	end

end

return view