
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/26/25
##
##  Make 3x1 grid for Fig 3
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
print("Create side-by-side figure for critical-mass / tipping point convergence")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  outputDir = paste(sourceDir, '/paperfigs/', sep = "")
  CriticalMass = paste(sourceDir, '/output/', '/simulation/', 'CritMass_ProbFlip.png', sep = "")
  FlipPureSim = paste(sourceDir, '/output/', '/simulation/', 'CritMass_EmpiricalCompare.png', sep = "")
  FlipEmpMem = paste(sourceDir, '/output/', '/simulation/', '/empiricalmemory/', 'CritMass_EmpiricalCompare.png', sep = "")
  output_name <- "SC_fig3_flipping.png"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 5) {
  outputDir = args[1]
  CriticalMass = args[2]
  FlipPureSim = args[3]
  FlipEmpMem = args[4]
  output_name = args[5]
}


##################################
## 0. Reading in base plots
setwd(sourceDir)

p.CriticalMass <- ggdraw() + draw_image(CriticalMass) + draw_label("(A)", x = 0.14, y = 0.85, hjust = 0, vjust = 1, size = axisTextSizeBig)
p.FlipPureSim <- ggdraw() + draw_image(FlipPureSim) + draw_label("(B)", x = 0.14, y = 0.85, hjust = 0, vjust = 1, size = axisTextSizeBig)
p.FlipEmpMem <- ggdraw() + draw_image(FlipEmpMem) + draw_label("(C)", x = 0.14, y = 0.85, hjust = 0, vjust = 1, size = axisTextSizeBig)


combined_plot <- plot_grid(p.CriticalMass, p.FlipPureSim, p.FlipEmpMem, nrow = 1)
if (RUN_LIVE) { combined_plot }

setwd(outputDir)
ggsave(plot = combined_plot,
       filename=output_name,
       width = 33, height = 11, units = "in") 
##################################
##################################

