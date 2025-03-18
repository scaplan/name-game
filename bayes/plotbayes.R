
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/19/25
##
##  Plotting / analysis for Bayesian simulation
###########################################################
###########################################################


rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Summary plotting of Bayes tipping point simulation...")
pdf(NULL)

## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (!RUN_LIVE) {
  if (length(args) == 3) {
    dataDir = args[1]
    targetInputFile = args[2]
    plotDir = args[3]
  } else {
    print("Incorrect number of input arguments! Exiting now...")
    stop("Incorrect number of input arguments")
  }
} else {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/bayestippingpoint/', sep = "")
  targetInputFile <- "bayes_tipping_point_simulation_roundbyround.csv"
  plotDir = paste(dataDir, 'plots', sep = "")
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()



##################################
## 0. Reading in data 
setwd(dataDir)
bayes_data <- read.csv(targetInputFile, stringsAsFactors = T,header=TRUE, sep = ",") # Read in the target words for each instance

bayes_data$CONFED_PROP <- as.factor(bayes_data$CONFED_PROP)
bayes_data$NETWORK_SIZE <- as.factor(bayes_data$NETWORK_SIZE)


if (RUN_LIVE) {
  sample.df <- bayes_data %>% filter(NETWORK_SIZE == 48, PRIOR == 0.8, UPDATE_SCALAR == 0.12)
  print(nrow(bayes_data))
  print(nrow(sample.df))
}
annotation_size <- 10
setwd(plotDir)
######################################
######################################

# Things that vary....
# NETWORK_SIZE
# PRIOR
# UPDATE_SCALAR



######################################
### Example param config plot

curr.prior = 0.8
curr.scalar = 0.22

sample.df <- bayes_data %>% filter(PRIOR == curr.prior, UPDATE_SCALAR == curr.scalar)

p24<-ggplot(subset(sample.df, NETWORK_SIZE == 24), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title="") + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none") + 
  annotate("text", x = 60, y = 0.9, label = "N = 24", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(A)", size = annotation_size)
if (RUN_LIVE) { p24 }
p48<-ggplot(subset(sample.df, NETWORK_SIZE == 48), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title=paste("", sep="")) + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none")  + 
  annotate("text", x = 60, y = 0.9, label = "N = 48", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(B)", size = annotation_size)
if (RUN_LIVE) { p48 }
p96<-ggplot(subset(sample.df, NETWORK_SIZE == 96), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title="") + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none") + 
  annotate("text", x = 60, y = 0.9, label = "N = 96", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(C)", size = annotation_size)
if (RUN_LIVE) { p96 }

legend <- get_legend(
  p24 + fig_1_single_pane_theme_no_legend() + theme(legend.position="right",
                                                    legend.title=element_text(size=axisTextSizeBig),
                                                    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
                                                    legend.text=element_text(size=axisTextSizeBig)) +
    labs(color = "Proportion of\nConfederates")
)

triple.pl <- plot_grid(p24, p48, p96, nrow=1,
                       legend,
                       rel_widths = c(1, 1, 1, 0.5))
if (RUN_LIVE) { triple.pl }
ggsave(plot = triple.pl,
       filename=paste("Bayes-tipping-point-PRIOR-", curr.prior, "-SCALAR-", curr.scalar, ".png", sep=""),
       width = 24, height = 8, units = "in") 




######################################
######################################


######################################
### For plotting averages

avg.df <- bayes_data %>% group_by(NETWORK_SIZE, CONFED_PROP, ROUNDNUM) %>% summarise(NEW_PROP = mean(NEW_PROP))

p24<-ggplot(subset(avg.df, NETWORK_SIZE == 24), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title="\n") + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none") + 
  annotate("text", x = 60, y = 1, label = "N = 24", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(A)", size = annotation_size)
if (RUN_LIVE) { p24 }
p48<-ggplot(subset(avg.df, NETWORK_SIZE == 48), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title=paste("Proportion of new name use\nin Bayesian Agents", sep="")) + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none")  + 
  annotate("text", x = 60, y = 1, label = "N = 48", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(B)", size = annotation_size)
if (RUN_LIVE) { p48 }
p96<-ggplot(subset(avg.df, NETWORK_SIZE == 96), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
  geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0,1.0)) + 
  scale_x_continuous(breaks=seq(10, 70, 10), limits = c(0,70)) + 
  labs(y="Prop. new name usage", x = "Round Number", title="\n") + 
  fig_1_single_pane_theme_no_legend() + theme(legend.position = "none") + 
  annotate("text", x = 60, y = 1, label = "N = 96", size = annotation_size) +
  annotate("text", x = 5, y = 1, label = "(C)", size = annotation_size)
if (RUN_LIVE) { p96 }

legend <- get_legend(
  p24 + fig_1_single_pane_theme_no_legend() + theme(legend.position="right",
                                                    legend.title=element_text(size=axisTextSizeBig),
                                                    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
                                                    legend.text=element_text(size=axisTextSizeBig)) +
    labs(color = "Proportion of\nConfederates")
)

triple.pl <- plot_grid(p24, p48, p96, nrow=1,
                       legend,
                       rel_widths = c(1, 1, 1, 0.5))
if (RUN_LIVE) { triple.pl }
ggsave(plot = triple.pl,
       filename=paste("Bayes-tipping-point-AVG-allParam", ".png", sep=""),
       width = 24, height = 8, units = "in") 

######################################
######################################


######################################
### For plotting every param config

# # Get levels for iteration
# all.priors <- unique(bayes_data$PRIOR)
# all.scalars <- unique(bayes_data$UPDATE_SCALAR)
# setwd(plotDir)
# for (curr.prior in all.priors) {
#   for (curr.scalar in all.scalars) {
#     df.curr.config <- bayes_data %>% filter(PRIOR == curr.prior, UPDATE_SCALAR == curr.scalar)
#     
#     # Line plot color/group by CONFED_PROP
#     p24<-ggplot(subset(df.curr.config, NETWORK_SIZE == 24), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
#       geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
#       ylim(0,1.0)+ 
#       labs(y="Prop. new name usage", x = "Round Number", title=paste("Prop. new name use in Bayesians (N=24)", sep="")) + 
#       single_pane_theme()
#     if (RUN_LIVE) { p24 }
#     p48<-ggplot(subset(df.curr.config, NETWORK_SIZE == 48), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
#       geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
#       ylim(0,1.0)+
#       labs(y="Prop. new name usage", x = "Round Number", title=paste("Prop. new name use in Bayesians (N=48)", sep="")) + 
#       single_pane_theme()
#     if (RUN_LIVE) { p48 }
#     p96<-ggplot(subset(df.curr.config, NETWORK_SIZE == 96), aes(x=ROUNDNUM, y=NEW_PROP, group=CONFED_PROP)) + annotate(geom = "rect", xmin=10, xmax=40, ymin=0, ymax=1.0, fill="#7CCD7C", alpha = 0.4) +
#       geom_line(aes(color=CONFED_PROP)) + geom_point(aes(color=CONFED_PROP))+
#       ylim(0,1.0)+
#       labs(y="Prop. new name usage", x = "Round Number", title=paste("Prop. new name use in Bayesians (N=96)", sep="")) + 
#       single_pane_theme()
#     if (RUN_LIVE) { p96 }
#     
#     # triple.pl <- plot_grid(p24, p48, p96, labels = c('24', '48', '96'), label_size = 12) # + single_pane_theme()
#     triple.pl <- plot_grid(p24, p48, p96) # + single_pane_theme()
#     if (RUN_LIVE) { triple.pl }
#     ggsave(plot = triple.pl,
#            filename=paste("Bayes-tipping-point-PRIOR-", curr.prior, "-SCALAR-", curr.scalar, ".png", sep=""),
#            width = 24, height = 12, units = "in") 
#   }
# }


######################################
######################################
