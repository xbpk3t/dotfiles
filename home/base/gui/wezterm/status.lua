return function(wezterm, config)
	local modes = {
		{ emoji = "🔥", context = "Keep going!" },
		{ emoji = "💻", context = "Code time" },
		{ emoji = "☕", context = "Coffee break" },
		{ emoji = "📚", context = "Study hard" },
		{ emoji = "🎧", context = "Focus mode" },
		{ emoji = "🚀", context = "To the moon" },
		{ emoji = "😎", context = "Stay cool" },
		{ emoji = "🌸", context = "享受片刻宁静" },
		{ emoji = "⚡", context = "Full power" },
		{ emoji = "📝", context = "Write it down" },
	}

	local current_mode_index = 1

	local function update_status(window, should_cycle_mode)
		-- 这里也是状态栏的时间的展示
		local date = wezterm.strftime '%Y-%m-%d %H:%M:%S'
		local hour = tonumber(wezterm.strftime '%H')

		local time_emoji
		if hour >= 6 and hour < 12 then
			time_emoji = "🌅"
		elseif hour >= 12 and hour < 18 then
			time_emoji = "🌞"
		else
			time_emoji = "🌙"
		end

		local current_mode = modes[current_mode_index]

		window:set_right_status(wezterm.format {
			-- 这里调整右边状态栏的样式
			{ Attribute = { Italic = true } },
			{ Attribute = { Underline = 'Single' } },
			{ Text = string.format("%s %s | %s %s  ", time_emoji, date, current_mode.emoji, current_mode.context) },
		})

		if should_cycle_mode then
			current_mode_index = (current_mode_index % #modes) + 1
		end
	end

	wezterm.on('update-right-status', function(window, pane)
		update_status(window, false)
	end)

	local function schedule_update(window)
		-- 这里可以调整时间
		wezterm.time.call_after(300.0, function()
			update_status(window, true)
			schedule_update(window)
		end)
	end

	wezterm.on('window-config-reloaded', function(window, pane)
		schedule_update(window)
	end)
end
