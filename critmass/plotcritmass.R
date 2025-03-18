
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/23/25
##
##  Plot tipping point critical mass simulations
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Plot tipping point critical mass simulations...")

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/simulation/', sep = "")
  targetInputFile <- "critmass_final_flip_outcomes_save.tsv"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 2) {
  dataDir = args[1]
  targetInputFile = args[2]
}

##################################
## 0. Reading in data and calculate aggregate results
setwd(dataDir)
df <- read.csv(targetInputFile, sep = "\t")
df$N <- as.character(df$N)
df$CM <- as.numeric(df$CM)
df$SIMULATION_NUMBER <- as.character(df$SIMULATION_NUMBER)
df <- df %>% group_by(AGENT_TYPE, N, M, CM, SIMULATION_NUMBER) %>% dplyr::mutate(flip = sum(NEW_PROP>0.5)>0)

df.aggregate <- df %>% group_by(AGENT_TYPE, N, M, CM) %>% reframe(pFLIP = sum(flip)/length(flip))
df.aggregate$N <- as.factor(df.aggregate$N)
df.aggregate$condition <- paste(df.aggregate$N, df.aggregate$AGENT_TYPE, sep="_")
df.aggregate$AGENT_TYPE <- as.factor(df.aggregate$AGENT_TYPE)
levels(df.aggregate$AGENT_TYPE)<-c("Optimize", "Imitate", "Threshold (TP)")
##################################
##################################



##################################
## 1. plot
p <-  ggplot(df.aggregate, aes(x = CM, y = pFLIP, color=AGENT_TYPE, shape=N, group=condition)) + fig_1_single_pane_theme_no_legend() +
 #  geom_rect(aes(xmin=0.2, xmax=0.3, ymin=-Inf, ymax=Inf), fill="lightblue", alpha=0.1, inherit.aes = FALSE) +
  geom_point(size=8) + geom_line(linewidth=1) + 
  scale_color_manual(values=c(BR_color, CB_color, TP_color)) + 
  xlab("Critical Mass") + ylab("P(Adopt Alternative Convention)") + 
  ggtitle("") + 
  theme(plot.title=element_text(size=30, hjust=0.5)) + 
  theme(
    legend.text=element_text(size=23),
    legend.title=element_blank(),
    legend.background = element_blank(),
    legend.position = "top",
    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4)) +
  coord_cartesian(xlim=c(0,0.5)) + scale_y_continuous(breaks=seq(0,1,0.1))
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename=paste("CritMass_ProbFlip", ".png", sep=""),
       width = 11, height = 11, units = "in") 
##################################
##################################

