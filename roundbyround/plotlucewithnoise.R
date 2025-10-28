
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
cat("Plot total round-by-round accuracy for Luce+Noise...")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  fileBase = "model_emp_results_round_by_round_all.tsv"
  outputDir = paste(sourceDir, '/output/model_empirical_roundbyround/', sep = "")
  Noise0 = paste(outputDir, 'M-12_LuceNoise-0_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise1 = paste(outputDir, 'M-12_LuceNoise-1_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise2 = paste(outputDir, 'M-12_LuceNoise-2_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise3 = paste(outputDir, 'M-12_LuceNoise-3_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
  Noise4 = paste(outputDir, 'M-12_LuceNoise-4_pop-FIFO_update-PENALIZE/', fileBase, sep = "")
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

N0_data <- read_ng_filter_confed(Noise0, RUN_LIVE)
N1_data <- read_ng_filter_confed(Noise1, RUN_LIVE)
N2_data <- read_ng_filter_confed(Noise2, RUN_LIVE)
N3_data <- read_ng_filter_confed(Noise3, RUN_LIVE)
N4_data <- read_ng_filter_confed(Noise4, RUN_LIVE)



# "get_accuracy_by_round_by_source" is defined in aux-functions.R
TP.results.byround <- get_accuracy_by_round_by_source(N0_data, "TP", "Source") %>% mutate(Noise = "Threshold (TP)") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N0.results.byround <- get_accuracy_by_round_with_stochastic(N0_data, "Luce", "Source") %>% mutate(Noise = "Pure Luce") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N1.results.byround <- get_accuracy_by_round_with_stochastic(N1_data, "Luce", "Source") %>% mutate(Noise = "Luce + 10% Second Choice") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N2.results.byround <- get_accuracy_by_round_with_stochastic(N2_data, "Luce", "Source") %>% mutate(Noise = "Luce + 20% Second Choice") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N3.results.byround <- get_accuracy_by_round_with_stochastic(N3_data, "Luce", "Source") %>% mutate(Noise = "Luce + 30% Second Choice") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N4.results.byround <- get_accuracy_by_round_with_stochastic(N4_data, "Luce", "Source") %>% mutate(Noise = "Luce + 40% Second Choice") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")

df.all <- bind_rows(N0.results.byround,
                    N1.results.byround, N2.results.byround, N3.results.byround, N4.results.byround)
df.all <- df.all %>% mutate(Model = ifelse(grepl("s", Noise, fixed = TRUE), "Luce-plus-noise",
                                           ifelse(Noise == "TP", "TP", "Luce-plus-noise")))


df.all.earlyrounds <- subset(df.all, RoundNum <= 40 & RoundNum > 10)

p <- ggplot(df.all.earlyrounds, aes(x=RoundNum, y=Accuracy, color = Noise)) +
  geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + # + four_model_color() + four_model_shape() +
  geom_hline(yintercept = 0.879, color = TP_color, linetype = "dashed", linewidth=4) + # Dashed red line
  scale_color_manual(values = c("Threshold (TP)" = TP_color,
                                "Pure Luce" = Luce_color,
                                "Luce + 10% Second Choice" = "#5E556E",
                                "Luce + 20% Second Choice" = "#7D7098",
                                "Luce + 30% Second Choice" = "#A398B3",
                                "Luce + 40% Second Choice" = "#B8A9C9")) +
  labs(y="Model Accuracy\nP(Predict Participant's Next Choice)", x = "Round") +
  fig_1_single_pane_theme(c(0.67, 0.13)) +
  # ylim(0,1) +
  scale_y_continuous(breaks=seq(0, 1, 0.1), limits = c(0.15, 1.0))

if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="SI_rbyr_accuracy_LucewithNoisePickSecondChoice.png",
       width = 11, height = 11, units = "in")



df.all.earlyrounds.grouped <- df.all.earlyrounds %>% group_by(Noise) %>% dplyr::summarise(Accuracy = mean(Accuracy), .groups = "drop_last")


# Send output to file instead of printing to standard out
sink("LucewithNoise_accuracy_astext.txt")
print(df.all.earlyrounds.grouped)
sink() # Stop sinking at the end before returning


##################################
##################################

