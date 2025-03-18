
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/19/25
##
##  Check the proportion of empirical output names
##  present in memory with respect to each model
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Name-in-memory analysis of CB2015/CBBB2018 ABM data...")


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))


args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/', sep = "")
  targetInputFile_fullRoundbyRound <- "model_emp_results_round_by_round_all.tsv"
  inMemoryOutputFile <- "modeling_name_in_memory.tsv"
  nameMemoryDistroFile <- "name_memory_distro_explore.csv"
  # topNameMemoryOutputPropFile <-"top_name_ratio_output_explore_22.csv"
  topNameMemoryOutputPropFile <-"top_name_ratio_output_explore_0.csv"
}


output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 5) {
  dataDir = args[1]
  targetInputFile_fullRoundbyRound = args[2]
  inMemoryOutputFile = args[3]
  nameMemoryDistroFile = args[4]
  topNameMemoryOutputPropFile = args[5]
}


##################################
## 0. Reading in data and filter confederate output
setwd(dataDir)
ng_data <- read_ng_filter_confed(targetInputFile_fullRoundbyRound, RUN_LIVE)
df.nameMemoryDistro <- read.csv(nameMemoryDistroFile)
df.nameMemPrep <- read.csv(topNameMemoryOutputPropFile)
##################################
##################################


## 
df.below.TP <- df.nameMemPrep %>% filter(Below_Above_TP == "below") %>% filter(SourcePaper == "BothCombined")
total.pre.TP.trials <- sum(df.below.TP$Trials)
total.pre.TP.plurality.output <- sum(df.below.TP$BR_Match)
memslots <- sum(df.below.TP$MemRatio_asProp * df.below.TP$Trials)
BR.rate <- total.pre.TP.plurality.output / total.pre.TP.trials
Mem.rate <- memslots / total.pre.TP.trials
if (RUN_LIVE) { BR.rate }
if (RUN_LIVE) { Mem.rate }

# Send output to file instead of printing to standard out
sink("below_TP_plurality_output_vs_mem.txt")
print(paste("Total trials (pre-TP): ", total.pre.TP.trials ,  sep = ""))
print(paste("BR.rate: ", BR.rate ,  sep = ""))
print(paste("Mem.rate: ", Mem.rate ,  sep = ""))
sink() # Stop sinking at the end before returning




## Generate plot showing correlation between memory slots and proportion of output

df.nameMemory.correl <- df.nameMemoryDistro %>% group_by(Round, NameNum) %>% summarise(Output = mean(ProductionProp), Memory = mean(MemoryProp), .groups = "drop_last")
df.nameMemory.correl$NameNum <- as.factor(df.nameMemory.correl$NameNum)
df.nameMemory.correl <- df.nameMemory.correl[df.nameMemory.correl$NameNum %in% c("Top", "Second", "Third", "other"), ]
df.nameMemory.correl$NameNum <- droplevels(df.nameMemory.correl$NameNum) 
df.nameMemory.correl$NameNum <- factor(df.nameMemory.correl$NameNum, levels=c("Top", "Second", "Third", "other"))

df.nameMemory.correl <- df.nameMemory.correl %>%
          rename("Memory slots" = Memory)  %>%
          rename("Name said" = Output)

df.nameMemory.correl.long <- df.nameMemory.correl %>% pivot_longer(cols = c("Name said", "Memory slots"),    # Columns to gather
                                                                   names_to = "Measure",          # New column name for the type of measure
                                                                   values_to = "Proportion")

# Quick statistical test
cor_test <- cor.test(df.nameMemory.correl.long$Proportion[df.nameMemory.correl.long$Measure == "Name said"], 
                     df.nameMemory.correl.long$Proportion[df.nameMemory.correl.long$Measure == "Memory slots"], 
                     method = "pearson")
if (RUN_LIVE) { print(cor_test) }




p <- ggplot(df.nameMemory.correl.long, aes(x = Round, y = Proportion, group = Measure, color = Measure)) +
  geom_point() +
  geom_smooth(aes(color = Measure), method = "lm", formula = y ~ x, se = FALSE) +
  facet_wrap(~ NameNum, ncol = 2) +
  labs(color =  paste("Pearson's correlation: ", round(cor_test$estimate, 2), sep="")) + 
  fig_1_single_pane_theme(c(0.25, 0.90)) + theme(strip.text = element_text(size = axisTextSize), legend.title = element_text(size = axisTextSize)) +
  # scale_y_continuous(breaks=seq(0, 1, 0.1), limits = c(0.1, 1.0)) + 
  scale_color_manual(values = c("Name said" = name_color,
                                "Memory slots" = memory_color)) +
  scale_x_continuous(breaks=seq(0, 26, 5), limits = c(0, 30))
if (RUN_LIVE) { print(p) }
ggsave(plot = p,
       filename=paste("Name-in-mem-vs-output", ".png", sep=""),
       width = 11, height = 11, units = "in") 





##################################
## 1. Output names in-memory plots
tabular_name_in_memory <- function(df, model.mem, model.name) {
  model.inmem.byround <- df %>%
    group_by(RoundNum, SourcePaper) %>%
    dplyr::summarise(Total = n(),
                     inmem = sum({{model.mem}},  na.rm=TRUE),
                     inmem.prop = inmem/Total,
                     .groups = 'drop') %>%
    subset(select=-c(inmem)) %>%
    mutate(Model = model.name)
  return(model.inmem.byround)
}


ng_data <- ng_data %>% group_by(SourcePaper) %>%
rowwise() %>%
  mutate(inTPmem = as.numeric(grepl(toString(EmpiricalOutput), TP.memory, fixed=TRUE))) %>%
  mutate(inBRmem = as.numeric(grepl(toString(EmpiricalOutput), BR.memory, fixed=TRUE))) %>%
  mutate(inCBmem = as.numeric(grepl(toString(EmpiricalOutput), CB.memory, fixed=TRUE)))

TPBR.inmem.byround <- tabular_name_in_memory(ng_data, inTPmem, "TP/BR")
CB.inmem.byround <- tabular_name_in_memory(ng_data, inCBmem, "CB")

# ng_data.inMem <- bind_rows(BR.inmem.byround, TP.inmem.byround, CB.inmem.byround)
ng_data.inMem <- bind_rows(TPBR.inmem.byround, CB.inmem.byround)
write.table(ng_data.inMem, file=inMemoryOutputFile, quote=FALSE, sep='\t', row.names = FALSE)

# for (curr_paper in PAPER_LIST) {
#   df.curr.exp <- ng_data.inMem %>% filter(SourcePaper == curr_paper)
#   
#   p<-ggplot(subset(df.curr.exp, RoundNum <= 40), aes(x=RoundNum, y=inmem.prop, group=Model)) +
#     geom_line(aes(color=Model)) + geom_point(aes(color=Model)) + ylim(0,1.0) + 
#     labs(y="Proportion of output names in memory", x = "Round Number",
#          title=paste("Proportion of empirical output present\n",
#                      "in agents' memory under {TP/BR} vs. CB (first 40 rounds)\n", curr_paper,
#                      sep="")) + 
#     single_pane_theme_withLegend(c(.8, .15)) + TPBR_vs_CB_two_set_color()
#   if (RUN_LIVE) { p } 
#   ggsave(plot = p, filename=paste("ByRound-empirical-inmemory-BR-TP-CB-",
#                         curr_paper, "-first40Rounds.png", sep=""),
#          width = 10, height = 8, units = "in")
# }
# ##################################
# ##################################


