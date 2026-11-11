hl.monitor({
  output = "DP-1",
  mode = "2560x1440@240",
  --mode = "1920x1080@165",
  --position = "4880x0",
  --transform = 0,
  --scale = 1,
  bitdepth = 10,
  --cm = "srgb",
})

hl.monitor({
  output = "DP-2",
  mode = "2560x1440@165",
  position = "0x0",
  transform = 1,
  scale = 1,
  bitdepth = 8,
  --cm = "srgb",
})

hl.monitor({
  output = "DP-3",
  mode = "3440x1440@164.90",
  position = "1440x0",
  transform = 0,
  scale = 1,
  bitdepth = 10,
  --cm = "srgb",
})
