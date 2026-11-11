local colors = require("modules.colors")

hl.config({
  general = {
    layout = "dwindle",
    allow_tearing = false,

    gaps_in = 10,
    gaps_out = 20,

    border_size = 1,
    col = {
	active_border = colors.surface,
	inactive_border = colors.surface,
    },
  },
  cursor = {
    zoom_disable_aa = true,
    zoom_detached_camera = false,
    no_hardware_cursors = 0
  },
  dwindle = {
    preserve_split = true,
  },
  decoration = {
    rounding = 15,
    rounding_power = 3,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    blur = {
      enabled = true,
      size = 10,
      passes = 2,
      vibrancy = 0.1696,
      ignore_opacity = true,
      new_optimizations = true,
      xray = true,
    },
    shadow = {
      enabled = true,
      range = 1,
      sharp = true,
      render_power = 1,
      color = colors.bg,
    },
    motion_blur = {
      enabled = false,
      samples = 10,
    },
  },
  misc = {
    vrr = 1,
  },
})

hl.layer_rule({
    name = "blur-quickshell",
    match = { namespace = "quickshell-ui"},
    blur = true,
    no_anim = true,
})

hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "45")
