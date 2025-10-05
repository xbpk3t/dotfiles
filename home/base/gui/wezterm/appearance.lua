return function(wezterm, config)
	-- 默认的长宽
	--config.initial_cols = 120
	--config.initial_rows = 28
    --
	--config.window_decorations = "RESIZE"
	---- 关掉才可以有顶部栏的样式调整
	--config.use_fancy_tab_bar = false
	--config.tab_max_width = 25
	--config.hide_tab_bar_if_only_one_tab = true  -- 从 Nix 配置迁移


	--config.font_size = 13  -- 从 Nix 的 13 调整
	--config.font = wezterm.font_with_fallback({
	--	'JetBrains Mono',
	--	'LXGW WenKai Screen',
	--	'Noto Color Emoji'
	--})
	--config.color_scheme = 'Catppuccin Mocha'

	-- 滚动历史 - 从 Nix 配置迁移
	--config.scrollback_lines = 5000

	-- 移除 Windows 特定的 default_prog 配置
	-- config.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }

	-- 标签栏与窗口边缘的空隙
	--config.window_padding = {
	--	top = 0,
	--}
end
