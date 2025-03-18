
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/13/24
##
##  Overall analysis of empirical name game data
##  with respect to each model
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Plot total round-by-round accuracy for BR+Noise...")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  fileBase = "model_emp_results_total_accuracy.tsv"
  outputDir = paste(sourceDir, '/output/model_empirical_roundbyround/', sep = "")
  Noise0 = paste(outputDir, 'M-12_noise-0_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise1 = paste(outputDir, 'M-12_noise-1_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise2 = paste(outputDir, 'M-12_noise-2_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise3 = paste(outputDir, 'M-12_noise-3_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise4 = paste(outputDir, 'M-12_noise-4_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 6) {
  outputDir = args[1]
  Noise0 = args[2]
  Noise1 = args[3]
  Noise2 = args[4]
  Noise3 = args[5]
  Noise4 = args[6]
}


##################################
## 0. Reading in base data
setwd(outputDir)

N0_data <- read_tsv(Noise0, show_col_types = FALSE)
N1_data <- read_tsv(Noise1, show_col_types = FALSE)
N2_data <- read_tsv(Noise2, show_col_types = FALSE)
N3_data <- read_tsv(Noise3, show_col_types = FALSE)
N4_data <- read_tsv(Noise4, show_col_types = FALSE)


TP.baseline <- N0_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.TP)
N0 <- N0_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.BR)
N1 <- N1_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.BR)
N2 <- N2_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.BR)
N3 <- N3_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.BR)
N4 <- N4_data %>% subset(SourcePaper == 'Both') %>% pull(Accuracy.BR)

Model <- c("0%", "10%", "20%", "30%", "40%")
Accuracy <- c(N0, N1, N2, N3, N4)

df.to.plot <- data.frame(
  Model = Model, # Four rows for Model
  Accuracy = Accuracy # Corresponding Accuracy values
)


p <- ggplot(df.to.plot, aes(x = Model, y = Accuracy)) +
  geom_col(fill = BR_color) + # Bar plot
  geom_hline(yintercept = TP.baseline, color = TP_color, linetype = "dashed", linewidth=4) + # Dashed red line
  # geom_abline(intercept = 0.69, slope = -0.015, color = "black", linetype = "dotted",  linewidth=2) + 
  # geom_smooth(method = "lm", color = "red", se = FALSE) + 
  labs(
    x = "Probability of Luce Sampling\nwithin Optimizing Agents",
    y = "Model Accuracy\nP(Predict Participant's Next Choice)"
  ) +
  fig_1_single_pane_theme_no_legend() + coord_cartesian(ylim = c(0.6,1))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="SI_rbyr_accuracy_BRwithNoise.png",
       width = 11, height = 11, units = "in")


# Send output to file instead of printing to standard out
sink("BRwithNoise_accuracy_astext.txt")
print(df.to.plot)
sink() # Stop sinking at the end before returning


##################################
##################################

