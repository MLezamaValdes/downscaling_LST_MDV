
library(ggplot)
library(rasterVis)
library(sf)

datdir <- "C:/Users/mleza/OneDrive/Documents/PhD/work_packages/auto_downscaling_30m/downscaleLST.MDV/data/"
aoadir <- "D:/downscaling_after_talk/aoa/results_split/"
imageoutdir <- "C:/Users/mleza/OneDrive/Documents/PhD/work_packages/auto_downscaling_30m/paper/paper_draft/figures/new/new_fig_6/"


# get function for figure
make_fig_function_path <- list.files("C:/Users/mleza/OneDrive/Documents/PhD/work_packages/auto_downscaling_30m/downscaleLST.MDV/R/",
                                     full.names = T, pattern="dsc_figure")
source(make_fig_function_path)

# load and prepare rasters
predoutpath <- "D:/downscaling_after_talk/predictions/"
sp <- raster(paste0(predoutpath, "pred_rf_MYD11_L2.A2018316.1350.006.2bilinmod.tif"))
full_grids <- readRDS(paste0(datdir, "full_size_grids_all_layers.RDS"))
diff <- sp - full_grids$L
aoa <- readRDS(paste0(datdir, "AOA.RDS"))

# make stack with all rasters
plotstack <- stack(full_grids$Mngb, sp, full_grids$L, diff, aoa)
names(plotstack) <- c("Modis", "downscaled_MODIS", "Landsat", "prediction error", "AOA")


# example extents
e2 <- extent(414049.3, 430820.4 , -1275424 ,-1254161)
e4 <- extent(420922, 429817, -1320557, -1307879)

ex2 <- crop(plotstack, e2)
ex4 <- crop(plotstack, e4)

# writeRaster(ex2$downscaled_MODIS, paste0(predoutpath, "ex2_dsc.tif"))

############## PLOTTING ###################################################

### full scene ################

options("scipen"=100, "digits"=4)
bry <- c(-1400000, -1300000, -1200000)
brx <- c(400000, 450000, 500000)

dscplot <- make_dsc_figure(LST = plotstack$downscaled_MODIS,  LST_name = "LST",
                 aoa=plotstack$AOA, ex=list(ex2, ex4), c=c("navy","chartreuse4"),
                 limlow = -40, limhigh = 0, exsize = 1,
                 limitx = c(350500, 500000), limity = c(-1400000, -1200000),
                 legendposition = "none", type=NULL,
                 brksy = bry, brksx = brx)
mplot <- make_dsc_figure(LST = plotstack$Modis,  LST_name = "MODIS LST",
                 ex=list(ex2, ex4), c=c("navy","chartreuse4"),
                 limlow = -40, limhigh = 0, exsize = 1,
                 limitx = c(350500, 500050), limity = c(-1400050, -1200000),
                 legendposition = "none",brksy = bry, brksx = brx)
lplot <- make_dsc_figure(LST = plotstack$Landsat,  LST_name = "Landsat LST",
               ex=list(ex2, ex4), c=c("navy","chartreuse4"),
               limlow = -40, limhigh = 0, exsize = 1,
               limitx = c(350500, 500050), limity = c(-1400050, -1200000),
               legendposition = "none", brksy = bry, brksx = brx)

diffplot <- make_dsc_figure(LST = plotstack$prediction.error,  LST_name = "Landsat LST",
                            ex=list(ex2, ex4), c=c("navy","chartreuse4"),
                            limlow = -12, limhigh = 12, legendposition = "none",
                            exsize = 1, type="diff",
                            limitx = c(350500, 500050), limity = c(-1400050, -1200000),
                            brksy = bry, brksx = brx)

plotlist <- list(mplot, dscplot, lplot, diffplot)

margin = theme(plot.margin = unit(c(0.7,0.7,0.4,0.4), "cm"))

png(paste0(imageoutdir, "spatimp_full.png"),
    units="cm", width=28, height=11, res=300)
grid.arrange(
  grobs = lapply(plotlist, "+", margin),
  layout_matrix = rbind(c(1,2,3,4)))
dev.off()



### example 2 #################
margin = ggplot2::theme(plot.margin = unit(c(0.4,0.4,0.4,0.4), "cm"))
# breaks can also be defined automatically by using scales::breaks_extended(n=xbreaks)
bry = c(-1270000, -1260000)
brx = c(420000, 425000)


dscplot <- make_dsc_figure(LST = ex2$downscaled_MODIS,  LST_name = "LST",
                           aoa=ex2$AOA, ex=list(ex2), c=c("navy"), 
                           limlow = -26, limhigh = -3, legendposition = "none",
                           exsize = 4, 
                           brksy = bry, brksx = brx)

mplot <- make_dsc_figure(LST = ex2$Modis,  LST_name = "MODIS LST",
                         limlow = -26, limhigh = -3,ex=list(ex2), c=c("navy"), legendposition = "none",
                         exsize = 4,
                         brksy = bry, brksx = brx)

lplot <- make_dsc_figure(LST = ex2$Landsat,  LST_name = "Landsat LST",
                         limlow = -26, limhigh = -3,ex=list(ex2), c=c("navy"), legendposition = "none",
                         exsize = 4,
                         brksy = bry, brksx = brx)

diffplot <- make_dsc_figure(LST = ex2$prediction.error,  LST_name = "Landsat LST",
                                     limlow = -12, limhigh = 12,ex=list(ex2), c=c("navy"), legendposition = "none",
                                     exsize = 3, type="diff",
                                    brksy = bry, brksx = brx)

plotlist <- list(mplot, dscplot, lplot, diffplot)


png(paste0(imageoutdir, "spatimp_ex2.png"),
    units="cm", width=30, height=12, res=300)

gridExtra::grid.arrange(
  grobs = lapply(plotlist, "+", margin),
  layout_matrix = rbind(c(1,2,3,4)))

dev.off()

# ggsave(paste0(figurepath, "spatial_improvement_", prednam,"small_extent_2.png"),
#        plot = pex2, dpi=300, width = 20, height=15, units = "cm")
# 

### example 4 #################
margin = ggplot2::theme(plot.margin = unit(c(0.4,0.4,0.4,0.4), "cm"))

bry<- c(-1319000, -1315000, -1310000)
brx <- c(425000)

dscplot <- make_dsc_figure(LST = ex4$downscaled_MODIS,  LST_name = "LST",
                           aoa=ex4$AOA, ex=list(ex4), c=c("chartreuse4"), 
                           limlow = -26, limhigh = -3, legendposition = "none",
                           exsize = 4,
                           brksy = bry, brksx = brx)

mplot <- make_dsc_figure(LST = ex4$Modis,  LST_name = "MODIS LST",
                         limlow = -26, limhigh = -3,ex=list(ex4), c=c("chartreuse4"), legendposition = "none",
                         exsize = 4,
                         brksy = bry, brksx = brx)

lplot <- make_dsc_figure(LST = ex4$Landsat,  LST_name = "Landsat LST",
                         limlow = -26, limhigh = -3,ex=list(ex4), c=c("chartreuse4"), legendposition = "none",
                         exsize = 4,
                         brksy = bry, brksx = brx)

diffplot <- make_dsc_figure(LST = ex4$prediction.error,  LST_name = "Landsat LST",
                            limlow = -12, limhigh = 12,ex=list(ex4), c=c("chartreuse4"), legendposition = "none",
                            exsize = 4,type="diff",
                            brksy = bry, brksx = brx)

plotlist <- list(mplot, dscplot, lplot, diffplot)

png(paste0(imageoutdir, "spatimp_ex4.png"),
    units="cm", width=28, height=11, res=300)

gridExtra::grid.arrange(
  grobs = lapply(plotlist, "+", margin),
  layout_matrix = rbind(c(1,2,3,4)))
dev.off()

# with legend
dscplot_with_legend <- make_dsc_figure(LST = ex4$downscaled_MODIS,  LST_name = "LST",
                                       aoa=ex4$AOA, ex=list(ex4), c=c("navy"), 
                                       limlow = -26, limhigh = -3,
                                       exsize = 1)

png(paste0(imageoutdir, "legend_dsc.png"),
    units="cm", width=10, height=9, res=300)

dscplot_with_legend
dev.off()

# with legend
diffplot_with_legend <- make_dsc_figure(LST = ex4$prediction.error,  
                                        LST_name = "LST \nprediction \nerror",
                                        ex=list(ex4), c=c("navy"), 
                                        limlow = -12, limhigh = 12,
                                        exsize = 1, type="diff", 
                                        legendposition = "top")

png(paste0(imageoutdir, "legend_diff.png"),
    units="cm", width=10, height=9, res=300)

diffplot_with_legend
dev.off()
