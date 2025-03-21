
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Plot threshold discontinuity effect at 
##  different cutoffs (induce TP)
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Plot regression discontinuity pre/post TP threshold...")

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/prepostthreshold/', sep = "")
  targetInputFile <- "check_other_thresholds_output_14.tsv"
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
M <- unique(coord.df$MemLimit)


earliest_round <- -M-1
latest_round <- M+1
# earliest_round <- -40
# latest_round <- 40

# coord.df <- subset(coord.df, RoundNum > 3 & RoundNum < 40)

if (RUN_LIVE) { nrow(coord.df) }
coord.df <- subset(coord.df, Thresh.Round != "None") # drop participants who never reached TP
if (RUN_LIVE) { nrow(coord.df) }
coord.df$Thresh.Round <- as.numeric(coord.df$Thresh.Round) # Round is numeric
coord.df$pre_post_thresh <- as.factor(coord.df$Thresh.Round >= 0)

# filter non-response trials
coord.df <- coord.df %>% filter(EmpiricalOutput != 'na' & InterlocutorOutput != 'na')
if (RUN_LIVE) { nrow(coord.df) }

# there shouldn't be any confed trials here
# but assert / double check here
coord.df <- coord.df %>% filter(IsConfed == 'FALSE')
if (RUN_LIVE) { nrow(coord.df) }

# Compute P(coordination success) and 
# add column for pre vs. post threshold as binary variable
coord.df.summary <- coord.df %>% group_by(Thresh, Thresh.Round) %>% summarise(prop_success = mean(CoordSuccess), n = n(), .groups = "drop_last") %>%
  mutate(pre_post_thresh = as.factor(Thresh.Round >= 0)) %>% filter(Thresh.Round > earliest_round & Thresh.Round < latest_round)

p <- ggplot(coord.df.summary,
            aes(x = Thresh.Round, y = prop_success)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size=5) + geom_smooth(formula = y ~ x, method = "lm", se = TRUE, aes(group = pre_post_thresh, color=pre_post_thresh), linewidth=2) +
  scale_color_manual(values = c("FALSE" = BRnonprod_color,
                                "TRUE" = TP_color)) +
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0.5) +
  facet_wrap(~Thresh) + 
  coord_cartesian(ylim=c(0,1)) +
  scale_y_continuous(breaks=seq(0,1,0.1))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename=paste("Induce-threshold-magnitude-explore-facet-discont-", M, ".png", sep=""),
       width = 11, height = 11, units = "in") 
##################################
##################################

  

##################################
## 1. Regressions across thresholds
across_thresh_magnitudes <- data.frame()
for(curr_TP in seq(1, M)) {
  curr_TP_data <- coord.df.summary %>% filter(Thresh == curr_TP)
  # curr_TP_data <- coord.df %>% filter(Thresh == curr_TP) %>% filter(Thresh.Round > earliest_round & Thresh.Round < latest_round)
  # curr_TP_data <- coord.df %>% filter(Thresh == curr_TP)
  reg.mod <- lm(prop_success ~ Thresh.Round * pre_post_thresh, data = curr_TP_data)
  # reg.mod <- glm(CoordSuccess ~ Thresh.Round * pre_post_thresh, data = curr_TP_data)
  reg.mod.summ <- summary(reg.mod)

  pre_post_effect<-reg.mod$coefficients[4]
  mod_summ_coeff<-as.data.frame(reg.mod.summ$coefficients)
  pre_post_pval<-mod_summ_coeff$`Pr(>|t|)`[4]

  curr.df <- data.frame(M=M, Mthresh = curr_TP, pre_post_effect = pre_post_effect, pre_post_pval = pre_post_pval)
  across_thresh_magnitudes<-rbind(across_thresh_magnitudes, curr.df)
}

across_thresh_magnitudes[1,]$pre_post_effect<-0
# across_thresh_magnitudes[2,]$pre_post_effect<-0
across_thresh_magnitudes$abs_pre_post_effect<-abs(across_thresh_magnitudes$pre_post_effect)

real_TP <- M - (floor(M/log(M)))
out_dist_plot <- across_thresh_magnitudes %>% mutate(TP = ifelse(Mthresh == real_TP, TRUE, FALSE))


# Printing discontinuity just for M=12
pre_trials <- coord.df %>% filter(Thresh == 12) %>% filter(Thresh.Round < 0)
post_trials <- coord.df %>% filter(Thresh == 12) %>% filter(Thresh.Round >= 0)
if (RUN_LIVE) { t.test(pre_trials$CoordSuccess, post_trials$CoordSuccess) }




##################################
##################################



##################################
## 2. Plotting
p <- ggplot(out_dist_plot, aes(x = Mthresh, y = abs_pre_post_effect, color = TP)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size=10) + geom_smooth(formula = y ~ x, method = "loess", linewidth=2, se=F, color="black") +
  ggtitle(paste("Memory: ", M, sep="")) +
  scale_color_manual(values=c("black", TP_color)) +
  xlab("Simulated Threshold") + ylab("Magnitude of Threshold Effect") +
  scale_x_continuous(breaks=seq(0,M,1)) +
  geom_vline(xintercept = real_TP, linewidth=2, color = TP_color)
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename=paste("Induce-threshold-magnitude-", M, ".png", sep=""),
       width = 11, height = 11, units = "in")
##################################
##################################





