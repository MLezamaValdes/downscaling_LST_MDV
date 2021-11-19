library(raster)
library(mapview)

expDir <- "D:/LST_paper_review/exposure/"

dem <- raster("C:/Users/mleza/OneDrive/Documents/PhD/work_packages/SurfaceMoisture/predictors/DEM_8m_MDV_filled_aoi.tif")

full_grid <- readRDS("C:/Users/mleza/OneDrive/Documents/PhD/work_packages/auto_downscaling_30m/downscaleLST.MDV/data/full_size_grids_all_layers.RDS")
comp_ex2 <- readRDS("C:/Users/mleza/OneDrive/Documents/PhD/work_packages/auto_downscaling_30m/downscaleLST.MDV/data/comp_ex2.RDS")

demex2 <- crop(dem, extent(comp_ex2))
# writeRaster(demex2, paste0(expDir, "small_DEM_ex2.tif"))

diff <- comp_ex2$downscaled-comp_ex2$L

mapview(diff)+mapview(comp_ex2$downscaled)+mapview(comp_ex2$L)

exp150 <- raster(paste0(expDir, "Wind_Expo_150.tif"))
exp150


mapview(diff)+mapview(exp150)
