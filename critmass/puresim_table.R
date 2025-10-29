
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
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
  targetInputFile <- "converge_puresim_outcomes_combined.tsv"
  outputFile <- "converge_puresim_table.txt"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 3) {
  dataDir = args[1]
  targetInputFile = args[2]
  outputFile = args[3]
}

##################################
## 0. Reading in data and output Latex table
setwd(dataDir)
df <- read.csv(targetInputFile, sep = "\t")
df$AGENT_TYPE <- as.factor(df$AGENT_TYPE)
# levels(df$AGENT_TYPE)<-c("Optimize", "Imitate", "Threshold (TP)")
levels(df$AGENT_TYPE)<-c("Optimize", "Imitate", "Luce", "Threshold (TP)")



agent_colors <- c(
  "Threshold (TP)" = "dodgerblue",
  "Optimize"       = "red",
  "Imitate"        = "forestgreen",
  "Luce"           = "grey"
)

# Create HTML labels for the y-axis
y_labels <- sapply(names(agent_colors), function(x) {
  label <- if (x == "Threshold (TP)") "Threshold<br>(TP)" else x
  paste0("<span style='color:", agent_colors[x], "'>", label, "</span>")
})
names(y_labels) <- names(agent_colors)



df.to.plot <- df %>% filter(W == 10) %>%
  mutate(AGENT_TYPE = factor(AGENT_TYPE, levels = c("Luce", "Threshold (TP)", "Imitate", "Optimize")))

p <-  ggplot(df.to.plot,
       aes(y = AGENT_TYPE, x = MEAN_ROUND,
           color = AGENT_TYPE, shape = factor(N))) +
  geom_point(position = position_dodge(width = 0.6), size = 8) +
  geom_errorbarh(
    aes(xmin = MEAN_ROUND - STD_DEV, xmax = MEAN_ROUND + STD_DEV),
    position = position_dodge(width = 0.6),
    height = 0.8, linewidth = 2
  ) + 
  annotate(geom = "rect", xmin=20, xmax=30, ymin=0, ymax=5.0, fill="#7CCD7C", alpha = 0.4) + 
  fig_1_single_pane_theme(c(0.85, 0.90)) + 
  labs(x = "Mean Round to Initial Convergence (± SD)", y = "Agent Type", shape = "N") +
  scale_color_manual(values = agent_colors) +
  scale_y_discrete(labels = y_labels ) +
  theme(
    plot.title = element_text(size = 30, hjust = 0.5),
    legend.text = element_text(size = 23),
    legend.background = element_blank(),
    legend.box.background = element_rect(colour = "black", fill = "white", linewidth = 1.4),
    axis.text.y = element_markdown(angle = 90, hjust = 0.5, vjust = 0.5)
  ) +  guides(color = "none", shape = guide_legend(title = "N",title.theme = element_text(size = 23)))
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename=paste("InitialConverge", ".png", sep=""),
       width = 11, height = 11, units = "in") 




df.print <- subset(df, select = -c(CONVERGED_SIMS, TOTAL_SIMS, M)) 
df.print <- df.print %>% rename(ABM = AGENT_TYPE)
df.print <- df.print %>% rename(`Network Size` = N)
df.print <- df.print %>% rename(`Word Distribution` = W)

# Format Mean (SD)
df.print.mean.sd <- df.print %>%
  mutate(`Converged Round (Std Dev)` = sprintf("%.2f (%.2f)", MEAN_ROUND, STD_DEV)) %>%
  select(-MEAN_ROUND, -STD_DEV)  # Remove old columns

df_w10 <- subset(df.print.mean.sd, `Word Distribution` == 10) %>% arrange(desc(ABM))
df_w100 <- subset(df.print.mean.sd, `Word Distribution` == 100) %>% arrange(desc(ABM))

wide_w10 <- df_w10 %>%
  pivot_wider(names_from = c(`Word Distribution`, `Network Size`), values_from = `Converged Round (Std Dev)`, 
              names_glue = "{`Word Distribution`}-{`Network Size`}")

wide_w100 <- df_w100 %>%
  pivot_wider(names_from = c(`Word Distribution`, `Network Size`), values_from = `Converged Round (Std Dev)`, 
              names_glue = "{`Word Distribution`}-{`Network Size`}")



# Send output to file instead of printing to standard out
sink(outputFile)
print(xtable(df_w10, align = "ll|ccc", booktabs = TRUE), include.rownames = FALSE)
print(xtable(df_w100, align = "ll|ccc", booktabs = TRUE), include.rownames = FALSE)
sink() # Stop sinking at the end before returning

