
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
cat("Summary analysis of CB2015/CBBB2018 modeling data...")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/', sep = "")
  targetInputFile <- "model_emp_results_round_by_round_all.tsv"
  summaryFile = "model_emp_results_total_accuracy.tsv"
  summaryRoundByRoundFile = "model_emp_results_roundbyround_accuracy.tsv"
}



output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 4) {
  dataDir = args[1]
  targetInputFile = args[2]
  summaryFile = args[3]
  summaryRoundByRoundFile = args[4]
}


##################################
## 0. Reading in data and filter confederate output
setwd(dataDir)
ng_data <- read_ng_filter_confed(targetInputFile, RUN_LIVE)
M <- as.character(unique(ng_data$MemLimit))
##################################
##################################




##################################
## 1. Model accuracy overall
# don't show summarise group.by warnings
options(dplyr.summarise.inform = FALSE)

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

get_accuracy_overall_deterministic_intersect <- function(df, model.one, model.two) {
  model.one.deterministic <- paste(model.one, ".deterministic", sep="")
  model.two.deterministic <- paste(model.two, ".deterministic", sep="")
  # total <- "Total"
  accuracy.one <- paste("Accuracy.", model.one, sep="")
  correct.one <- paste("Correct.", model.one, sep="")
  score.one <- paste(model.one, ".score", sep="")
  accuracy.two <- paste("Accuracy.", model.two, sep="")
  correct.two <- paste("Correct.", model.two, sep="")
  score.two <- paste(model.two, ".score", sep="")
  
  head.to.head.accuracy <- df %>%
    group_by(!!sym(model.one.deterministic), !!sym(model.two.deterministic), SourcePaper) %>% 
    summarise(Total = n(),
              !!sym(correct.one) := sum(as.numeric(eval(as.name(score.one)))),
              !!sym(accuracy.one) := eval(as.name(correct.one))/Total,
              !!sym(correct.two) := sum(as.numeric(eval(as.name(score.two)))),
              !!sym(accuracy.two) := eval(as.name(correct.two))/Total) %>%
    filter(!!sym(model.one.deterministic) == "True" & !!sym(model.two.deterministic) == "True") %>%
    subset(select=-c(eval(as.name(model.one.deterministic)), eval(as.name(model.two.deterministic))))
  
  return(head.to.head.accuracy)
}


CB.results <- get_accuracy_overall(ng_data, "CB")
BR.results <- get_accuracy_overall(ng_data, "BR")
TP.results <- get_accuracy_overall(ng_data, "TP")
CBTP_headtohead_results <- get_accuracy_overall_deterministic_intersect(ng_data, "TP", "CB")
###
ng_filter <- ng_data %>% filter(BR.deterministic == "True" & TP.deterministic == "False")
BRnonprod_results <- get_accuracy_overall(ng_filter, "BR") %>%
  rename(Total.BRnonprod  = Total.BR, Correct.BRnonprod = Correct.BR, Accuracy.BRnonprod = Accuracy.BR)



results_list <- list(CB.results, BR.results, TP.results, BRnonprod_results) 
combined.results <- results_list %>% reduce(full_join, by='SourcePaper')

bothPapers <- combined.results %>% dplyr::summarise(Total.CB=sum(Total.CB),
                                      Correct.CB=sum(Correct.CB),
                                      Accuracy.CB=mean(Accuracy.CB),
                                      Total.BR=sum(Total.BR),
                                      Correct.BR=sum(Correct.BR),
                                      Accuracy.BR=mean(Accuracy.BR),
                                      Total.TP=sum(Total.TP),
                                      Correct.TP=sum(Correct.TP),
                                      Accuracy.TP=mean(Accuracy.TP),
                                      Total.BRnonprod=sum(Total.BRnonprod),
                                      Correct.BRnonprod=sum(Correct.BRnonprod),
                                      Accuracy.BRnonprod=mean(Accuracy.BRnonprod))
bothPapers$SourcePaper = "Both"
combined.results <- bind_rows(combined.results, bothPapers)
combined.results$M <- M


if (RUN_LIVE) { combined.results }
write.table(combined.results, file=summaryFile, quote=FALSE, sep='\t', row.names = FALSE)


# CBBB2018 just post-confed
ng_data_late <- subset(ng_data, RoundNum > 20)
CB.results <- get_accuracy_overall(ng_data_late, "CB")
BR.results <- get_accuracy_overall(ng_data_late, "BR")
TP.results <- get_accuracy_overall(ng_data_late, "TP")
CBTP_headtohead_results <- get_accuracy_overall_deterministic_intersect(ng_data_late, "TP", "CB")
###
ng_filter <- ng_data_late %>% filter(BR.deterministic == "True" & TP.deterministic == "False")
BRnonprod_results <- get_accuracy_overall(ng_filter, "BR") %>%
  rename(Total.BRnonprod  = Total.BR, Correct.BRnonprod = Correct.BR, Accuracy.BRnonprod = Accuracy.BR)
results_list <- list(CB.results, BR.results, TP.results, BRnonprod_results) 
combined.results <- results_list %>% reduce(full_join, by='SourcePaper')



# Proportion test
TP.hits <- sum(TP.results$Correct.TP)
TP.total <- sum(TP.results$Total.TP)
BR.hits <- sum(BR.results$Correct.BR)
BR.total <- sum(BR.results$Total.BR)
TP.BR.prop <- prop.test(x = c(TP.hits, BR.hits), n = c(TP.total, BR.total))
sink_vars(c("TP.hits", "TP.total", "BR.hits", "BR.total", "TP.BR.prop"), "proportion-tests.txt")

CB.hits <- sum(CB.results$Correct.CB)
CB.total <- sum(CB.results$Total.CB)
TP.CB.prop <- prop.test(x = c(TP.hits, CB.hits), n = c(TP.total, CB.total))
sink_vars(c("TP.hits", "TP.total", "CB.hits", "CB.total", "TP.CB.prop"), "proportion-tests.txt", TRUE)

BRnonprod.hits <- sum(BRnonprod_results$Correct.BRnonprod)
BRnonprod.total <- sum(BRnonprod_results$Total.BRnonprod)
TP.BRnonprod.prop <- prop.test(x = c(TP.hits, BRnonprod.hits), n = c(TP.total, BRnonprod.total))
CB.BRnonprod.prop <- prop.test(x = c(CB.hits, BRnonprod.hits), n = c(CB.total, BRnonprod.total))
sink_vars(c("BRnonprod.hits", "BRnonprod.total", "TP.BRnonprod.prop", "CB.BRnonprod.prop"), "proportion-tests.txt", TRUE)
##################################
##################################


##################################
## 2. Model accuracy round-by-round

# Tabulate round-by-round
CB.results.byround <- get_accuracy_by_round_by_source(ng_data, "CB", "Source") # "get_accuracy_by_round_by_source" is defined in aux-functions.R
BR.results.byround <- get_accuracy_by_round_by_source(ng_data, "BR", "Source")
TP.results.byround <- get_accuracy_by_round_by_source(ng_data, "TP", "Source")

ng_filter <- ng_data %>% filter(BR.deterministic == "True" & TP.deterministic == "False")
BRnonprod_results.byRound <- get_accuracy_by_round_by_source(ng_filter, "BR", "Source") %>% mutate(Model = "BRnonprod")

df.all.by.round.by.source <- bind_rows(CB.results.byround, BR.results.byround, TP.results.byround, BRnonprod_results.byRound)
if (RUN_LIVE) { df.all.by.round.by.source }
write.table(df.all.by.round.by.source, file=summaryRoundByRoundFile, quote=FALSE, sep='\t', row.names = FALSE)
##################################
##################################




##################################
## 3. Plotting

df.all.by.round.by.source$Model<-as.factor(df.all.by.round.by.source$Model)
levels(df.all.by.round.by.source$Model)<-c("Optimize", "Optimize (pre-TP)", "Imitate", "Threshold (TP)")
df.all.by.round.by.source.bothPaperAvg <- df.all.by.round.by.source %>% group_by(RoundNum, Model) %>% dplyr::summarise(Accuracy=mean(Accuracy,na.rm=T), TotalTrials = sum(Total))


# for (roundSet in c("earlyrounds", "allrounds"))  {
for (roundSet in c("earlyrounds"))  {
  if (roundSet == "earlyrounds") {
    df.to.plot <- subset(df.all.by.round.by.source.bothPaperAvg, RoundNum <= 40)
  } else {
    # Placeholder in case we want to include all rounds (it gets very sparse that far out though)
    df.to.plot <- df.all.by.round.by.source.bothPaperAvg
  }
  # Only include rounds for each model when there are at least 10 total trials (can't get sufficiently precise estimate of results otherwise)
  df.to.plot <- subset(df.to.plot, TotalTrials >= 10)
  
  p<-ggplot(df.to.plot, aes(x=RoundNum, y=Accuracy, shape = Model, color = Model)) +
    geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + four_model_color() + four_model_shape() +
    labs(y="Model Accuracy\nP(Predict Participant's Next Choice)", x = "Round") +
    fig_1_single_pane_theme(c(0.75, 0.15)) +
    # ylim(0,1) +
    scale_y_continuous(breaks=seq(0, 1, 0.1), limits = c(0.1, 1.0))
  
  # Add M annotation
  p <- ggdraw(p) + draw_text(paste("M = ", M, sep=""), x = 0.97, y = 0.97, hjust = 1, vjust = 1, size = axisTextSizeBig)
  if (RUN_LIVE) { p }
  
  ggsave(plot = p,
         filename=paste("fig1_rbyr_accuracy_combined_new_", roundSet,".png", sep=""),
         width = 11, height = 11, units = "in")
}

##################################
##################################


