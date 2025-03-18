
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/21/25
##
##  Make 2x1 grid for Fig 2
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
print("Create side-by-side figure for pre-post threshold performance")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  outputDir = paste(sourceDir, '/paperfigs/', sep = "")
  CoordSuccess = paste(sourceDir, '/output/', '/prepostthreshold/', 'Coord-Success-Pre-Post-TP-12.png', sep = "")
  InduceThreshold = paste(sourceDir, '/output/', '/prepostthreshold/', 'Induce-threshold-magnitude-12.png', sep = "")
  output_name <- "SC_fig2_prepost.png"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 4) {
  outputDir = args[1]
  CoordSuccess = args[2]
  InduceThreshold = args[3]
  output_name = args[4]
}


##################################
## 0. Reading in base plots
setwd(sourceDir)

p.CoordSuccess <- ggdraw() + draw_image(CoordSuccess) + draw_label("(A)", x = 0.14, y = 0.92, hjust = 0, vjust = 1, size = axisTextSizeBig)
p.InduceThreshold <- ggdraw() + draw_image(InduceThreshold) + draw_label("(B)", x = 0.14, y = 0.92, hjust = 0, vjust = 1, size = axisTextSizeBig)


combined_plot <- plot_grid(p.CoordSuccess, p.InduceThreshold, nrow = 1)

setwd(outputDir)
ggsave(plot = combined_plot,
       filename=output_name,
       width = 22, height = 11, units = "in") 
##################################
##################################

