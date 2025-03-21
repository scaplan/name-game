
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Overall analysis of empirical name game data
##  with respect to each model
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Plot r-by-r accuracy in a grid over different M...")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  plotBase = "fig1_rbyr_accuracy_combined_new_earlyrounds.png"
  outputDir = paste(sourceDir, '/output/model_empirical_roundbyround/', sep = "")
  pathplotM8 = paste(outputDir, 'M-8_noise-0_pop-FIFO_update-PENALIZE/', plotBase, sep = "")
  pathplotM10 =paste(outputDir, 'M-10_noise-0_pop-FIFO_update-PENALIZE/', plotBase, sep = "")
  pathplotM14 = paste(outputDir, 'M-14_noise-0_pop-FIFO_update-PENALIZE/', plotBase, sep = "")
  pathplotM16 = paste(outputDir, 'M-16_noise-0_pop-FIFO_update-PENALIZE/', plotBase, sep = "")
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 5) {
  outputDir = args[1]
  pathplotM8 = args[2]
  pathplotM10 = args[3]
  pathplotM14 = args[4]
  pathplotM16 = args[5]
}


##################################
## 0. Reading in base plots
setwd(sourceDir)

plotM8 <- ggdraw() + draw_image(pathplotM8) + draw_label("(A)", x = 0.18, y = 0.96, hjust = 0, vjust = 1, size = axisTextSizeBig)
plotM10 <- ggdraw() + draw_image(pathplotM10) + draw_label("(B)", x = 0.18, y = 0.96, hjust = 0, vjust = 1, size = axisTextSizeBig)
plotM14 <- ggdraw() + draw_image(pathplotM14) + draw_label("(C)", x = 0.18, y = 0.96, hjust = 0, vjust = 1, size = axisTextSizeBig)
plotM16 <- ggdraw() + draw_image(pathplotM16) + draw_label("(D)", x = 0.18, y = 0.96, hjust = 0, vjust = 1, size = axisTextSizeBig)

combined_plot <- plot_grid(plotM8, plotM10, plotM14, plotM16, nrow = 1)

setwd(outputDir)
ggsave(plot = combined_plot,
       filename="SI_fig2_rbyr_across_M.png",
       width = 32, height = 8, units = "in") 
##################################
##################################

