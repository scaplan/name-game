
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Make 3x1 grid for Fig 2
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
print("Create 3-panel figure for: Accuracy by mem-size, early memory vs. output correlation, and later round-by-round accuracy")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  outputDir = paste(sourceDir, '/paperfigs/', sep = "")
  MemIndependent = paste(sourceDir, '/output/', '/model_empirical_roundbyround/', 'figS1_total_accuracy_by_M.png', sep = "")
  EarlyLuce = paste(sourceDir, '/output/', '/model_empirical_roundbyround/', '/M-12_noise-0_pop-FIFO_update-PENALIZE/', 'Name-in-mem-vs-output-superearly.png', sep = "")
  RoundByRound = paste(sourceDir, '/output/', '/model_empirical_roundbyround/', '/M-12_noise-0_pop-FIFO_update-PENALIZE/', 'fig1_rbyr_accuracy_combined_new_zoomin.png', sep = "")
  output_name <- "SC_fig2_twostage_rbyr.png"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 5) {
  outputDir = args[1]
  EarlyLuce = args[2]
  RoundByRound = args[3]
  MemIndependent = args[4]
  output_name = args[5]
}


##################################
## 0. Reading in base plots
setwd(sourceDir)

p.MemIndependent <- ggdraw() + draw_image(MemIndependent) + draw_label("(A)", x = 0.20, y = 0.92, hjust = 0, vjust = 1, size = axisTextSizeBig)
p.EarlyLuce <- ggdraw() + draw_image(EarlyLuce) + draw_label("(B)", x = 0.16, y = 0.92, hjust = 0, vjust = 1, size = axisTextSizeBig)
p.RoundByRound <- ggdraw() + draw_image(RoundByRound) + draw_label("(C)", x = 0.20, y = 0.92, hjust = 0, vjust = 1, size = axisTextSizeBig)


combined_plot <- plot_grid(p.MemIndependent, p.EarlyLuce, p.RoundByRound, nrow = 1)
if (RUN_LIVE) { combined_plot }

setwd(outputDir)
ggsave(plot = combined_plot,
       filename=output_name,
       width = 33, height = 11, units = "in") 
##################################
##################################

