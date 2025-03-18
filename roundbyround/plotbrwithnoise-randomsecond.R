
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

# Get the round-by-round files..... need to merge together....'
# Include TP, BR, and then noise or noise-PS at each level

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  fileBase = "model_emp_results_round_by_round_all.tsv"
  outputDir = paste(sourceDir, '/output/model_empirical_roundbyround/', sep = "")
  Noise0 = paste(outputDir, 'M-12_noise-0_pop-FIFO_update-PENALIZE', sep = "")
  Noise1 = paste(outputDir, 'M-12_noise-1_pop-FIFO_update-PENALIZE', sep = "")
  Noise2 = paste(outputDir, 'M-12_noise-2_pop-FIFO_update-PENALIZE', sep = "")
  Noise3 = paste(outputDir, 'M-12_noise-3_pop-FIFO_update-PENALIZE', sep = "")
  Noise4 = paste(outputDir, 'M-12_noise-4_pop-FIFO_update-PENALIZE', sep = "")
  Noise1PS = paste(Noise1, '-picksecond', sep = "")
  Noise2PS = paste(Noise2, '-picksecond', sep = "")
  Noise3PS = paste(Noise3, '-picksecond', sep = "")
  Noise4PS = paste(Noise4, '-picksecond', sep = "")
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 7) {
  outputDir = args[1]
  Noise0 = args[2]
  Noise1 = args[3]
  Noise2 = args[4]
  Noise3 = args[5]
  Noise4 = args[6]
  fileBase = args[7]
  # print(Noise0)
  Noise1PS = paste(Noise1, '-picksecond', sep = "")
  Noise2PS = paste(Noise2, '-picksecond', sep = "")
  Noise3PS = paste(Noise3, '-picksecond', sep = "")
  Noise4PS = paste(Noise4, '-picksecond', sep = "")
}


##################################
## 0. Reading in base data
setwd(outputDir)


N0_data <- read_ng_filter_confed(paste(Noise0, "/", fileBase, sep = ""), RUN_LIVE)
N1_data <- read_ng_filter_confed(paste(Noise1, "/", fileBase, sep = ""), RUN_LIVE)
N2_data <- read_ng_filter_confed(paste(Noise2, "/", fileBase, sep = ""), RUN_LIVE)
N3_data <- read_ng_filter_confed(paste(Noise3, "/", fileBase, sep = ""), RUN_LIVE)
N4_data <- read_ng_filter_confed(paste(Noise4, "/", fileBase, sep = ""), RUN_LIVE)
N1PS_data <- read_ng_filter_confed(paste(Noise1PS, "/", fileBase, sep = ""), RUN_LIVE)
N2PS_data <- read_ng_filter_confed(paste(Noise2PS, "/", fileBase, sep = ""), RUN_LIVE)
N3PS_data <- read_ng_filter_confed(paste(Noise3PS, "/", fileBase, sep = ""), RUN_LIVE)
N4PS_data <- read_ng_filter_confed(paste(Noise4PS, "/", fileBase, sep = ""), RUN_LIVE)

# "get_accuracy_by_round_by_source" is defined in aux-functions.R
TP.results.byround <- get_accuracy_by_round_by_source(N0_data, "TP", "Source") %>% mutate(Noise = "Threshold (TP)") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N0.results.byround <- get_accuracy_by_round_by_source(N0_data, "BR", "Source") %>% mutate(Noise = "Pure Optimize") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N1PS.results.byround <- get_accuracy_by_round_by_source(N1PS_data, "BR", "Source") %>% mutate(Noise = "OP + 10% Pick Second") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N2PS.results.byround <- get_accuracy_by_round_by_source(N2PS_data, "BR", "Source") %>% mutate(Noise = "OP + 20% Pick Second") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N3PS.results.byround <- get_accuracy_by_round_by_source(N3PS_data, "BR", "Source") %>% mutate(Noise = "OP + 30% Pick Second") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")
N4PS.results.byround <- get_accuracy_by_round_by_source(N4PS_data, "BR", "Source") %>% mutate(Noise = "OP + 40% Pick Second") %>% group_by(RoundNum, Model, Noise) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total), .groups = "drop_last")

# df.all <- bind_rows(TP.results.byround, N0.results.byround, N1.results.byround,
#                     N2.results.byround, N3.results.byround, N4.results.byround,
#                     N1PS.results.byround, N2PS.results.byround, N3PS.results.byround, N4PS.results.byround)
df.all <- bind_rows(TP.results.byround, N0.results.byround,
                    N1PS.results.byround, N2PS.results.byround, N3PS.results.byround, N4PS.results.byround)
df.all <- df.all %>% mutate(Model = ifelse(grepl("s", Noise, fixed = TRUE), "BR-plus-second",
                                           ifelse(Noise == "TP", "TP", "BR-plus-random")))


df.all.earlyrounds <- subset(df.all, RoundNum <= 40)
  
  
p <- ggplot(df.all.earlyrounds, aes(x=RoundNum, y=Accuracy, color = Noise)) +
  geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + # + four_model_color() + four_model_shape() +
  scale_color_manual(values = c("Threshold (TP)" = TP_color,
                                "Pure Optimize" = BR_color,
                                "OP + 10% Pick Second" = BR_pick_second, "OP + 20% Pick Second" = "purple3", "OP + 30% Pick Second" = "purple2", "OP + 40% Pick Second" = "purple1")) +
  labs(y="Model Accuracy\nP(Predict Participant's Next Choice)", x = "Round") +
  fig_1_single_pane_theme(c(0.65, 0.20)) +
  # ylim(0,1) +
  scale_y_continuous(breaks=seq(0, 1, 0.1), limits = c(0.1, 1.0))

if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="SI_rbyr_accuracy_BRwithNoisePickSecond.png",
       width = 11, height = 11, units = "in")


df.all.earlyrounds.grouped <- df.all.earlyrounds %>% group_by(Noise) %>% dplyr::summarise(Accuracy = mean(Accuracy), .groups = "drop_last")

# Send output to file instead of printing to standard out
sink("BRwithNoise_PickSecond_accuracy_astext.txt")
print(df.all.earlyrounds.grouped)
sink() # Stop sinking at the end before returning

##################################
##################################

