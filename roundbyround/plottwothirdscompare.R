
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Comparing TP with a hypothetical "2/3rds" rule
##  for the values of M and states when those rules diverge
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
  targetInputFile <- "TWO_THIRDS_COMPARE.tsv"
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
result_data <- result_data %>% mutate(TP = `TP-CORRECT` / `TOTAL-ROUNDS`,
                                      `2/3rds` = `TWOTHIRDS-CORRECT` / `TOTAL-ROUNDS`)  %>%
  select(c(MEMSIZE, TP, `2/3rds`)) %>%
  rename(M = MEMSIZE)

df_long <- result_data %>%
  pivot_longer(cols = c(TP, `2/3rds`), names_to = "Threshold", values_to = "Accuracy") %>%
  mutate(M = factor(as.character(M)))
##################################
##################################


p <- ggplot(df_long, aes(x = M, y = Accuracy, fill = Threshold)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  labs(x = "M (Memory size)", y = "Model Accuracy\nP(Predict Participant's Next Choice)", fill = "Threshold") +
  scale_fill_manual(values = c("TP" = TP_color, `2/3rds` = BR_pick_second)) +
  fig_1_single_pane_theme(c(0.75, 0.15)) + 
  scale_y_continuous(breaks=seq(0.0, 1.0, 0.2), limits = c(0.0, 0.9)) +
  theme(
    legend.position = "top",
    legend.title = element_blank(),   # optional: remove legend title
    legend.background = element_blank()
  )
if (RUN_LIVE) { p }
ggsave(plot = p,
       filename="figSX_compare_TP_two-thirds.png",
       width = 11, height = 11, units = "in")

##################################
## 1. Make plot over M

wide.data$Model<-as.factor(wide.data$Model)
wide.data <- wide.data %>%
  mutate(Model = fct_relevel(Model, "Optimize", "Optimize (pre-TP)", "Imitate", "Luce (post-TP)", "Threshold (TP)"))
# levels(wide.data$Model)<-c("Optimize", "Optimize (pre-TP)", "Imitate", "Luce (post-TP)", "Threshold (TP)")

p<-ggplot(wide.data, aes(x=M, y=Accuracy, shape = Model, color = Model)) +
  geom_point(size=8, position = pd) + geom_line(linewidth=2, position = pd) + five_model_color() + five_model_shape() +
  labs(y="Model Accuracy\nP(Predict Participant's Next Choice)", x = "Memory Size (M)") +
  fig_1_single_pane_theme(c(0.75, 0.15)) +
  scale_y_continuous(breaks=seq(0.4, 1.0, 0.1), limits = c(0.45, 1.0)) + 
  scale_x_continuous(breaks=seq(8, 26, 4), limits = c(7, 27))
if (RUN_LIVE) { p }

ggsave(plot = p,
       filename="figS1_total_accuracy_by_M.png",
       width = 11, height = 11, units = "in")
##################################
##################################
