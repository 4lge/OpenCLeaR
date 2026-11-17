library(rgl)
library(misc3d)

# 1. Stichproben auf der GPU generieren (matrix() statt as.matrix()!)
mu <- c(1, 2, 3)
Sigma <- matrix(c(1,    0.5,  0.25,
                  0.5,  1,    0.5,
                  0.25, 0.5,  1), nrow = 3, ncol = 3)

samples <- rmvnormOCL(100000L, mean = mu, sigma = Sigma)

# 2. 3D-Kerndichteschätzung (KDE) auf einem 50x50x50-Gitter berechnen
dens3d <- kde3d(samples[, 1], samples[, 2], samples[, 3], n = 50)

# 3. Kontur-Levels bei 10%, 40% und 75% der maximalen Dichte festlegen
max_d <- max(dens3d$d)
levels <- c(0.10, 0.40, 0.75) * max_d

# 4. Interaktiven 3D-Plot öffnen und Isosurfaces zeichnen
open3d()
contour3d(
  f     = dens3d$d,
  level = levels,
  x     = dens3d$x,
  y     = dens3d$y,
  z     = dens3d$z,
  color = c("steelblue", "orange", "firebrick"),
  alpha = c(0.15, 0.35, 0.85), # Außen transparent, Kern deckend
  add   = TRUE
)

# 5. Achsen, Beschriftung und eine kleine Stichprobe von Punkten ergänzen
axes3d()
title3d(xlab = "X1", ylab = "X2", zlab = "X3", main = "3D MVN Density (OpenCL)")
points3d(samples[1:500, ], col = "black", size = 2, alpha = 0.3)
