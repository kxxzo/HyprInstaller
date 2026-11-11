if hl.plugin.dynamic_cursors then
  hl.config {
    plugin = {
      dynamic_cursors = {
        enabled = true,
        mode = "stretch",
	stretch = {
          limit = 3000,
          activation = "quadratic",
          window = 100
        },
	shake = {
          enabled = true,
          threshold = 6.0,
          base = 4.0,
          speed = 4.0,
          influence = 1.0,
          limit = 8.0,
          timeout = 2000,
          effects = false,
	},
	hyprcursor = {
	  enabled = true,
	  nearest = 1,
	  resolution = -1,
	  fallback = "clientside",
	}
      },
    },
  }
end
