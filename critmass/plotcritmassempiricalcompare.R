
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
cat("Plot tipping point critical mass simulations compare empirical...")

args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()


## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



if (RUN_LIVE) {
  currMachine <- Sys.info()[['nodename']]
  # dataDir = paste(sourceDir, '/output/simulation/', sep = "")
  dataDir = paste(sourceDir, '/output/simulation/haltempirical/', sep = "")
  # dataDir = paste(sourceDir, '/output/simulation/keeplast/', sep = "")
  targetInputFile <- "empirical_flipping_compare_puresum.tsv"
  input_title = "Pure Simulation"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 3) {
  dataDir = args[1]
  targetInputFile = args[2]
  input_title = args[3]
}

##################################
## 0. Reading in data and calculate aggregate results
setwd(dataDir)
df <- read.csv(targetInputFile, sep = "\t")
df$AGENT_CLASS <- as.factor(df$AGENT_CLASS)
levels(df$AGENT_CLASS)<-c("Optimize", "Imitate", "Threshold (TP)")



# Create buckets....
# Too fast
# Within 10(+/-)
# Too slow
# Never flipped
match_string <- "Good Match (within 15 rounds)"

df.cat <- df %>% mutate(FlipCat = case_when(abs_diff <= 15 ~ match_string,
                                        abs_diff >= 150 ~ "Never Flipped",
                                        FLIP_ROUND - round_num > 15 ~ "Too Fast",
                                        TRUE ~ "Too Slow")
)

df.sum <- df.cat %>% group_by(AGENT_CLASS, FlipCat) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(AGENT_CLASS) %>%
  mutate(proportion = count / sum(count)) %>%
  mutate(rightwrong = ifelse(FlipCat == match_string, "Correct", "Incorrect")) %>%
  rename_at('AGENT_CLASS', ~'ABM')
levels(df.sum$ABM)<-c("OP", "IM", "TP")
df.sum$ABM <- factor(df.sum$ABM, levels=c('TP', 'OP', 'IM'))


p <- ggplot(df.sum, aes(x = ABM, y = proportion, fill = FlipCat, group = rightwrong)) +
  geom_bar(stat = "identity", position = position_dodge(width = 1)) +
 # geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = c("#1f78b4", "#d62728", "#ffcc00", "#6a3d9a")) +
  scale_y_continuous( breaks=c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0), limits = c(0, 1))  + 
  facet_wrap(~rightwrong) +
  labs(title = "Pure Simulation Outcome Type (Exact Convergence Window)",
       x = "ABM",
       y = "Proportion",
       fill = "Outcome Type") +
  single_pane_theme() +
  theme(legend.position="top")
if (RUN_LIVE) { p }
# ggsave(plot = p,
#        filename=paste("Crit-Mass_OutcomeClass", ".png", sep=""),
#        width = 16.5, height = 11, units = "in") 


# Paper stats
if (RUN_LIVE) { 
  prop_table <- xtabs(count ~ ABM + rightwrong, data = df.sum)
  pairwise.prop.test(prop_table, p.adjust.method = "bonferroni")
}





# Remove non-flipped runs...
df <- df %>% filter(abs_diff < 150)



# df %>% group_by(instance_id) %>% dplyr::summarize(emp.flip.round = mean(FLIP_ROUND))
# df %>% group_by(AGENT_CLASS) %>% dplyr::summarize(ABM.flip = mean(round_num))
if (RUN_LIVE) { mean(df$FLIP_ROUND) }
if (RUN_LIVE) { mean(subset(df, AGENT_CLASS == "Imitate")$FLIP_ROUND) }
if (RUN_LIVE) { mean(subset(df, AGENT_CLASS == "Optimize")$FLIP_ROUND) }
if (RUN_LIVE) { mean(subset(df, AGENT_CLASS == "Threshold (TP)")$FLIP_ROUND) }

df.aggregate <- df %>% group_by(AGENT_CLASS) %>% dplyr::summarize(ac.match = mean(abs_diff), emp.flip.round = mean(FLIP_ROUND), sim.flip.round = mean(round_num), n = n())
if (RUN_LIVE) { df.aggregate }

##################################
##################################


mean_values <- df %>%
  group_by(instance_id, AGENT_CLASS) %>%
  dplyr::summarize(mean_abs_diff = mean(abs_diff), .groups = "drop")

# T-test for paper
df.TP <- subset(df, AGENT_CLASS == "Threshold (TP)")$abs_diff
df.BR <- subset(df, AGENT_CLASS == "Optimize")$abs_diff
df.CB <- subset(df, AGENT_CLASS == "Imitate")$abs_diff
if (RUN_LIVE) { t.test(df.TP, df.BR) }
if (RUN_LIVE) { t.test(df.TP, df.CB) }


p <-  ggplot(df, aes(x = round_num, fill = AGENT_CLASS)) + fig_1_single_pane_theme_no_legend() +
  geom_density(alpha=0.5, color="black", adjust=2) + 
  scale_fill_manual(values=c( BR_color, CB_color, TP_color)) +  
  ggtitle(input_title) + 
  xlab("Average Flipping Round") + ylab("Density") + theme(
    legend.text=element_text(size=30),
    legend.title=element_blank(),
    legend.background = element_blank(),
    legend.position = "top",
    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
    panel.background = element_blank(), axis.line = element_line(colour = "black")) + 
  scale_x_continuous( breaks=seq(0, 150, 20), limits = c(-20, 150))  + 
  coord_cartesian(xlim=c(-5, 150))
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename=paste("MeanFLippingRound", ".png", sep=""),
       width = 11, height = 11, units = "in") 



##################################
## 1. plot
p <-  ggplot(df, aes(x = abs_diff, fill = AGENT_CLASS)) + fig_1_single_pane_theme_no_legend() +
  geom_density(alpha=0.5, color="black", adjust=2) + 
  scale_fill_manual(values=c( BR_color, CB_color, TP_color)) +  
  ggtitle(input_title) + 
  xlab("Error in Predicting Empirical Trials\n(Absolute Difference in Convergence Time)") + ylab("Density") + theme(
    legend.text=element_text(size=30),
    legend.title=element_blank(),
    legend.background = element_blank(),
    legend.position = "top",
    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
    panel.background = element_blank(), axis.line = element_line(colour = "black")) + 
  scale_x_continuous( breaks=c(0, 10, 20, 30, 40, 50), limits = c(-30, 200))  + 
  coord_cartesian(xlim=c(-5, 60)) + 
  geom_vline(xintercept = subset(df.aggregate, AGENT_CLASS=="Threshold (TP)")$ac.match, color=TP_color, linewidth=3) +
  geom_vline(xintercept = subset(df.aggregate, AGENT_CLASS=="Optimize")$ac.match, color=BR_color, linewidth=3) +
  geom_vline(xintercept = subset(df.aggregate, AGENT_CLASS=="Imitate")$ac.match, color=CB_color, linewidth=3)
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename=paste("CritMass_EmpiricalCompare", ".png", sep=""),
       width = 11, height = 11, units = "in") 


p <-  ggplot(df, aes(x = abs_diff, fill = AGENT_CLASS)) + fig_1_single_pane_theme_no_legend() +
  geom_density(alpha=0.5, color="black", adjust=2) + 
  scale_fill_manual(values=c( BR_color, CB_color, TP_color)) +  
  facet_wrap(~instance_id) +
  geom_vline(data = mean_values, aes(xintercept = mean_abs_diff, color = AGENT_CLASS), linewidth=3) + 
  scale_color_manual(values=c(BR_color, CB_color, TP_color)) +
  ggtitle(input_title) + 
  xlab("Error in Predicting Empirical Trials\n(Absolute Difference in Convergence Time)") + ylab("Density") + theme(
    legend.text=element_text(size=30),
    legend.title=element_blank(),
    legend.background = element_blank(),
    legend.position = "top",
    legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
    panel.background = element_blank(), axis.line = element_line(colour = "black")) + 
  scale_x_continuous( breaks=c(0, 10, 20, 30, 40, 50), limits = c(-30, 200))  + 
  coord_cartesian(xlim=c(-5, 60)) # + 
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename=paste("CritMass_EmpiricalCompare_facetWrap", ".png", sep=""),
       width = 22, height = 14, units = "in") 
##################################
##################################

