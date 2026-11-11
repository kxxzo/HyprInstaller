-------------
-- Springs --
-------------

hl.curve( "smooth-slow", { type = "spring", mass = 1, stiffness = 600, dampening = 45 })
hl.curve( "smooth-fast", { type = "spring", mass = 1, stiffness = 800, dampening = 60 })
hl.curve( "smooth-ultra-fast", { type = "spring", mass = 1, stiffness = 1000, dampening = 70 })
hl.curve( "smooth-max", { type = "spring", mass = 1, stiffness = 5000, dampening = 200 })

hl.curve( "soft-slow", { type = "spring", mass = 1, stiffness = 600, dampening = 40 })
hl.curve( "soft-fast", { type = "spring", mass = 1, stiffness = 800, dampening = 55 })

hl.curve( "semi-slow", { type = "spring", mass = 1, stiffness = 600, dampening = 35 })
hl.curve( "semi-fast", { type = "spring", mass = 1, stiffness = 800, dampening = 50 })

hl.curve( "hard-slow", { type = "spring", mass = 1, stiffness = 600, dampening = 30 })
hl.curve( "hard-fast", { type = "spring", mass = 1, stiffness = 800, dampening = 45 })

----------------
-- Animations --
----------------

hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "soft-slow", style = "slide left" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, spring = "soft-slow", style = "slide right" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "semi-slow" })
hl.animation({ leaf = "border", enabled = true, speed = 1, spring = "smooth-slow" })

hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, spring = "smooth-fast", style = "slide top" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, spring = "smooth-fast", style = "slide top" })

hl.animation({ leaf = "layersIn", enabled = true, speed = 1, spring = "smooth-ultra-fast", style = "popin 50%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1, spring = "smooth-max", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1, spring = "smooth-ultra-fast" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1, spring = "smooth-ultra-fast" })

hl.animation({ leaf = "fadeIn", enabled = true, speed = 1, spring = "smooth-ultra-fast" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1, spring = "smooth-ultra-fast" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 1, spring = "smooth-fast" })
