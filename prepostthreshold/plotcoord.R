
###########################################################
###########################################################
##  Author: Spencer Caplan
##  Last Modified: 02/20/25
##
##  Plot probability of coordination success
##  before and after reaching TP threshold
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Plot P(coordination success) pre/post TP threshold...")

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/prepostthreshold/', sep = "")
  targetInputFile <- "coordprob_output_12.tsv"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()


if (length(args) == 2) {
  dataDir = args[1]
  targetInputFile = args[2]
}



##################################
## 0. Reading in data and filter confeds / non-response
setwd(dataDir)
coord.df <- read.csv(targetInputFile, sep = "\t")

if (RUN_LIVE) { nrow(coord.df) }
coord.df <- subset(coord.df, TP.Round != "None") # drop participants who never reached TP
if (RUN_LIVE) { nrow(coord.df) }
coord.df$TP.Round <- as.numeric(coord.df$TP.Round) # Round is numeric

# filter non-response trials
coord.df <- coord.df %>% filter(EmpiricalOutput != 'na' & InterlocutorOutput != 'na')
if (RUN_LIVE) { nrow(coord.df) }

# there shouldn't be any confed trials here
# but assert / double check here
coord.df <- coord.df %>% filter(IsConfed == 'FALSE')
if (RUN_LIVE) { nrow(coord.df) }

# Compute P(coordination success) and 
# add column for pre vs. post threshold as binary variable
coord.df.summary <- coord.df %>% group_by(TP.Round) %>% summarise(prop_success = mean(CoordSuccess), n = n(), TP.score = mean(TP.score), BR.score = mean(BR.score), .groups = "drop_last") %>%
  mutate(pre_post_thresh = as.factor(TP.Round >= 0))




# for paper (accuracy when between 10-20 rounds from TP)
pre_tp_data <- coord.df %>% filter(TP.Round <= -10 & TP.Round >= -20)

if (RUN_LIVE) { mean(pre_tp_data$CoordSuccess) } # coord success
if (RUN_LIVE) { mean(pre_tp_data$BR.score) } # BR accuracy
if (RUN_LIVE) { binom.test(x = sum(pre_tp_data$CoordSuccess), n = nrow(pre_tp_data), p = 0.5) } # coord success lower than 50 %

# Send output to file instead of printing to standard out
sink("pre-TP-coord-prob-plus-BR-accuracy.txt")
print("# for paper (accuracy when between 10-20 rounds from TP)")
print(paste("mean(pre_tp_data$CoordSuccess): ", mean(pre_tp_data$CoordSuccess) ,  sep = ""))
print(paste("mean(pre_tp_data$BR.score): ", mean(pre_tp_data$BR.score) ,  sep = ""))
print(binom.test(x = sum(pre_tp_data$CoordSuccess), n = nrow(pre_tp_data), p = 0.5))
sink() # Stop sinking at the end before returning




##################################
##################################
 

##################################
## 1. Plotting

M <- unique(coord.df$MemLimit)
if (M == "RANDOM") {
  p.title <- "Memory (uniformly sampled 8-16)"
  p.xlab <- "Rounds from TP"
} else {
  p.title <- paste("Memory: ", M, sep="")
  p.xlab <- "Rounds from TP (8/12 Memory)"
}

dist.df.center <- coord.df.summary %>% filter(TP.Round > -22 & TP.Round < 20)
if (RUN_LIVE) { dist.df.center }


p <- ggplot(dist.df.center, 
       aes(x = TP.Round, y = prop_success)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size=5) + geom_smooth(formula = y ~ x, method = "lm", se = TRUE, aes(group = pre_post_thresh, color=pre_post_thresh), linewidth=2) + 
  scale_color_manual(values = c("FALSE" = BRnonprod_color,
                                "TRUE" = TP_color)) +
  ggtitle(p.title) + 
  xlab(p.xlab) + ylab("P(Coordination Success)") +
  geom_vline(xintercept = 0) + 
  geom_hline(yintercept = 0.5) + 
  coord_cartesian(ylim=c(0,1)) + 
  scale_y_continuous(breaks=seq(0,1,0.1))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename=paste("Coord-Success-Pre-Post-TP-", M, ".png", sep=""),
       width = 11, height = 11, units = "in") 




p <- ggplot(dist.df.center, 
            aes(x = TP.Round, y = BR.score)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size=5) + geom_smooth(formula = y ~ x, method = "lm", se = TRUE, aes(group = pre_post_thresh, color=pre_post_thresh), linewidth=2) + 
  scale_color_manual(values = c("FALSE" = BRnonprod_color,
                                "TRUE" = TP_color)) +
  ggtitle(p.title) + 
  xlab(p.xlab) + ylab("Optimization Model Accuracy\nP(Predict Participant's Next Choice)") +
  geom_vline(xintercept = 0) + 
  geom_hline(yintercept = 0.5) + 
  coord_cartesian(ylim=c(0,1)) + 
  scale_y_continuous(breaks=seq(0,1,0.1))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename=paste("BR-Accuracy-Pre-Post-TP-", M, ".png", sep=""),
       width = 11, height = 11, units = "in") 



p <- ggplot(dist.df.center, 
            aes(x = TP.Round, y = TP.score)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size=5) + geom_smooth(formula = 'y ~ x', method = "lm", se = TRUE, aes(group = pre_post_thresh, color=pre_post_thresh), linewidth=2) + 
  scale_color_manual(values = c("FALSE" = BRnonprod_color,
                                "TRUE" = TP_color)) +
  ggtitle(p.title) + 
  xlab(p.xlab) + ylab("Threshold Model Accuracy\nP(Predict Participant's Next Choice)") +
  geom_vline(xintercept = 0) + 
  geom_hline(yintercept = 0.5) + 
  coord_cartesian(ylim=c(0,1)) + 
  scale_y_continuous(breaks=seq(0,1,0.1))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename=paste("TP-Accuracy-Pre-Post-TP-", M, ".png", sep=""),
       width = 11, height = 11, units = "in") 


