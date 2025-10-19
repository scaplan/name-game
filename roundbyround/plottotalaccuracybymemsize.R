
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
result_data <- result_data %>% subset(select=c(Accuracy.CB, Accuracy.BR, Accuracy.Luce, Accuracy.TP, M))

# Convert from long to wide
wide.data <- result_data %>% rename(Optimize = Accuracy.BR,
                       Imitate = Accuracy.CB,
                       Luce = Accuracy.Luce,
                       "Threshold (TP)" = Accuracy.TP) %>%
  pivot_longer(!M, names_to = "Model", values_to = "Accuracy")
##################################
##################################


##################################
## 1. Make plot over M

wide.data$Model<-as.factor(wide.data$Model)
wide.data <- wide.data %>%
  mutate(Model = fct_relevel(Model, "Optimize", "Imitate", "Luce", "Threshold (TP)"))
# levels(wide.data$Model)<-c("Optimize", "Optimize (pre-TP)", "Imitate", "Luce (post-TP)", "Threshold (TP)")

p<-ggplot(wide.data, aes(x=M, y=Accuracy, shape = Model, color = Model)) +
  geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + four_model_color_luce_simple() + four_model_shape_luce_simple() +
  labs(y="Model Accuracy\nP(Predict Participant's Next Choice)", x = "Memory Size (M)") +
  fig_1_single_pane_theme(c(0.75, 0.35)) +
  scale_y_continuous(breaks=seq(0.3, 1, 0.15), limits = c(0.3, 0.95)) + 
  scale_x_continuous(breaks=seq(8, 20, 4), limits = c(7, 21))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="figS1_total_accuracy_by_M.png",
       width = 11, height = 11, units = "in")
##################################
##################################



# M-8_noise-0_pop-FIFO_update-PENALIZE
# M-10_noise-0_pop-FIFO_update-PENALIZE
# M-12_noise-0_pop-FIFO_update-PENALIZE

# model_emp_results_round_by_round_all.tsv

# df.all.12 <- read_tsv(paste(dataDir, "/M-12_noise-0_pop-FIFO_update-PENALIZE/", "model_emp_results_round_by_round_all.tsv", sep = ""), show_col_types = FALSE)
df.all.12 <- read_ng_filter_confed(paste(dataDir, "/M-12_noise-0_pop-FIFO_update-PENALIZE/", "model_emp_results_round_by_round_all.tsv", sep = ""), RUN_LIVE)




get_accuracy_overall <- function(df, model.name) {
  model.deterministic <- paste(model.name, ".deterministic", sep="")
  accuracy <- paste("Accuracy.", model.name, sep="")
  correct <- paste("Correct.", model.name, sep="")
  total <- paste("Total.", model.name, sep="")
  score <- paste(model.name, ".score", sep="")
  
  model.accuracy <- df %>%
    group_by(!!sym(model.deterministic), SourcePaper) %>% 
    summarise(!!sym(total) := n(),
              !!sym(correct) := sum(as.numeric(eval(as.name(score)))),
              !!sym(accuracy) := eval(as.name(correct))/eval(as.name(total))) %>%
    filter(!!sym(model.deterministic) == "True") %>%
    subset(select=-c(eval(as.name(model.deterministic))))
  
  return(model.accuracy)
}


get_accuracy_overall_plus_stochastic <- function(df, model.name) {
  accuracy <- paste("Accuracy.", model.name, sep="")
  correct <- paste("Correct.", model.name, sep="")
  total <- paste("Total.", model.name, sep="")
  score <- paste(model.name, ".score", sep="")
  
  model.accuracy <- df %>%
    group_by(SourcePaper) %>% 
    summarise(!!sym(total) := n(),
              !!sym(correct) := sum(as.numeric(eval(as.name(score)))),
              !!sym(accuracy) := eval(as.name(correct))/eval(as.name(total)))
  
  return(model.accuracy)
}

df.all.12.firstforty <- df.all.12 %>% filter(RoundNum < 41 & RoundNum > 15)

accuracy.luce.all.12 <- get_accuracy_overall_plus_stochastic(df.all.12.firstforty, "Luce")
accuracy.BR.all.12 <- get_accuracy_overall_plus_stochastic(df.all.12.firstforty, "BR")
accuracy.CB.all.12 <- get_accuracy_overall_plus_stochastic(df.all.12.firstforty, "CB")
accuracy.TP.all.12 <- get_accuracy_overall_plus_stochastic(df.all.12.firstforty, "TP")

# get_accuracy_overall(df.all.12.firstforty, "Luce")
get_accuracy_overall(df.all.12.firstforty, "BR")
get_accuracy_overall(df.all.12.firstforty, "CB")
get_accuracy_overall(df.all.12.firstforty, "TP")

results_list_12 <- list(accuracy.CB.all.12, accuracy.BR.all.12, accuracy.luce.all.12, accuracy.TP.all.12) 
combined.results <- results_list_12 %>% reduce(full_join, by='SourcePaper')

bothPapers <- combined.results %>% dplyr::summarise(Total.CB=sum(Total.CB),
                                                    Correct.CB=sum(Correct.CB),
                                                    Accuracy.CB=mean(Accuracy.CB),
                                                    Total.BR=sum(Total.BR),
                                                    Correct.BR=sum(Correct.BR),
                                                    Accuracy.BR=mean(Accuracy.BR),
                                                    Total.TP=sum(Total.TP),
                                                    Correct.TP=sum(Correct.TP),
                                                    Accuracy.TP=mean(Accuracy.TP),
                                                    Total.Luce=sum(Total.Luce),
                                                    Correct.Luce=sum(Correct.Luce),
                                                    Accuracy.Luce=mean(Accuracy.Luce))
bothPapers$SourcePaper = "Both"
combined.results.12 <- bind_rows(combined.results, bothPapers) # %>% select(c(Accuracy.CB, Accuracy.BR, Accuracy.Luce, Accuracy.TP))



accuracy.all.12.by.source <- bind_rows(accuracy.CB.all.12, accuracy.BR.all.12, accuracy.TP.all.12, accuracy.luce.all.12)
if (RUN_LIVE) { accuracy.all.12.by.source }

accuracy.luce.all.12 <- accuracy.luce.all.12 %>% group_by(Model) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total))



# 
# 
# CB.results <- get_accuracy_overall(ng_data, "CB")
# BR.results <- get_accuracy_overall(ng_data, "BR")
# TP.results <- get_accuracy_overall(ng_data, "TP")
# Luce.results <- get_accuracy_overall_plus_stochastic(ng_data, "Luce") # new rnr

