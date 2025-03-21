
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
cat("Plot total accuracy as a function of M...")

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  setwd("/Users/spcaplan/Dropbox/CS_accounts/penn_CS_account/satisficing/name-game/")
}


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/model_empirical_roundbyround/', sep = "")
  targetInputFile <- "model_scores_across_M.tsv"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 2) {
  dataDir = args[1]
  targetInputFile = args[2]
}


##################################
## 0. Reading in data and drop unneeded columns
setwd(dataDir)
result_data <- read_tsv(targetInputFile, show_col_types = FALSE)
result_data <- result_data %>% subset(SourcePaper == 'Both')
result_data <- result_data %>% subset(select=c(Accuracy.CB, Accuracy.BR, Accuracy.TP, Accuracy.BRnonprod, M))

# Convert from long to wide
wide.data <- result_data %>% rename(Optimize = Accuracy.BR,
                       "Optimize (pre-TP)" = Accuracy.BRnonprod,
                       Imitate = Accuracy.CB,
                       "Threshold (TP)" = Accuracy.TP) %>%
  pivot_longer(!M, names_to = "Model", values_to = "Accuracy")
##################################
##################################


##################################
## 1. Make plot over M

wide.data$Model<-as.factor(wide.data$Model)
# levels(wide.data$Model)<-c("Optimize", "Optimize (pre-TP)", "Imitate", "Threshold (TP)")

p<-ggplot(wide.data, aes(x=M, y=Accuracy, shape = Model, color = Model)) +
  geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + four_model_color() + four_model_shape() +
  labs(y="Accuracy in Predicting\nAgents' Round Choices", x = "Memory Size (M)") +
  fig_1_single_pane_theme(c(0.75, 0.15)) +
  scale_y_continuous(breaks=seq(0.4, 1.0, 0.1), limits = c(0.45, 1.0)) + 
  scale_x_continuous(breaks=seq(8, 26, 4), limits = c(7, 27))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="figS1_total_accuracy_by_M.png",
       width = 11, height = 11, units = "in")
##################################
##################################
