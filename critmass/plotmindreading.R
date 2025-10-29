
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Analysis and plotting for the Mind Reading experiment
###########################################################
###########################################################

rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Analysis and figure for new Mind Reading game experiment...")

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
  inputFile16 <- paste(sourceDir, '/data/MR/v4_FINAL_TP_16round_5_8_clean.csv', sep = "")
  inputFile18 <- paste(sourceDir, '/data/MR/v4_FINAL_TP_18round_6_9_clean.csv', sep = "")
  inputFile20 <- paste(sourceDir, '/data/MR/v4_FINAL_TP_20round_6_10_clean.csv', sep = "")
  inputFile24 <- paste(sourceDir, '/data/MR/v4_FINAL_TP_24round_7_12_clean.csv', sep = "")
  modelInputFile <- paste(sourceDir, "/output/mind_reading/M-12_var-2_update-PENALIZE/MR_model_out.tsv", sep = "")
  outputTable <- "MindReading_Results_Table.txt"
  outputPlot <- "SC_MindReading_Results_Penalize.png"
}

output_message <- load_in_libraries()
load_in_plot_aesthetics()

if (length(args) == 7) {
  inputFile16 <- args[1]
  inputFile18 <- args[2]
  inputFile20 <- args[3]
  inputFile24 <- args[4]
  modelInputFile <- args[5]
  outputTable <- args[6]
  outputPlot <- args[7]
}



###########
#Load Data#
###########
dt1 <- read.csv(inputFile16)
dt1$condition <- "16_5_8"
dt1_simp <- dt1 %>% select(ProlificID, final_categorical, version, condition)

dt2 <- read.csv(inputFile18)
dt2$condition <- "18_6_9"
dt2_simp <- dt2 %>% select(ProlificID, final_categorical, version, condition)

dt3 <- read.csv(inputFile20)
dt3$condition<-"20_6_10"
dt3_simp<-dt3 %>% select(ProlificID, final_categorical, version, condition)

dt4 <- read.csv(inputFile24) 
dt4$condition<-"24_7_12"
dt4_simp<-dt4 %>% select(ProlificID, final_categorical, version, condition)

dt_all <- rbind(dt1_simp, dt2_simp, dt3_simp, dt4_simp)
dt_all$condition <- as.factor(dt_all$condition)

##########
#Org Data#
##########
if (RUN_LIVE) {
  dt_all %>%
    group_by(condition, final_categorical) %>%
    summarise(n = n(), .groups = "drop_last") %>%
    mutate(frac = n / sum(n)) %>% filter(final_categorical == "2")
}

model.results <- read.csv(modelInputFile, sep="\t") 
model.results <- model.results %>% filter(INFILE != "MEAN")

## Make table 
df.human <- dt_all %>%
  group_by(condition, final_categorical) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(frac = n / sum(n)) %>% filter(final_categorical == "2")

df.table <- model.results %>%
  left_join(df.human %>% select(condition, frac),
            by = c("INFILE" = "condition")) %>%
  rename(Empirical = frac) %>%
  mutate(INFILE = substr(INFILE, 1, 2)) %>%
  rename(condition = INFILE)

df_flipped <- df.table %>% select(-c(TP.sd, BR.sd, TWOTHIRDS.sd, LUCE.sd)) %>%
  pivot_longer(
    cols = -condition,
    names_to = "Measure",
    values_to = "Value"
  ) %>%
  pivot_wider(
    names_from = condition,
    values_from = Value
  )

df_with_mean_error <- df_flipped %>%
  mutate(across(-Measure, as.numeric)) %>%
  {
    # Extract the empirical values as a numeric vector
    empirical_vec <- filter(., Measure == "Empirical") %>%
      select(-Measure) %>%
      as.numeric()
    
    mutate(
      .,
      mean_error = rowMeans(select(., -Measure) -
                              matrix(empirical_vec, nrow = n(), ncol = length(empirical_vec), byrow = TRUE)),
      mean_abs_error = rowMeans(abs(select(., -Measure) -
                                      matrix(empirical_vec, nrow = n(), ncol = length(empirical_vec), byrow = TRUE)))
    )
  }
sink(outputTable)
print(df_with_mean_error)
sink()

m.sd.comb <- df.table %>%
  mutate(across(-condition, ~ round(.x, 3))) %>%
  pivot_longer(
    cols = -c(condition, Empirical),
    names_to = c("Model", ".value"),
    names_pattern = "(.*)\\.(m|sd)"
  ) %>%
  mutate(stat = paste0(m, " (", sd, ")")) %>%
  select(condition, Model, stat, Empirical) %>%
  pivot_wider(
    names_from = Model,
    values_from = stat
  )
sink(outputTable, append = TRUE)
print(m.sd.comb)
sink()





model.result.avg <- model.results %>% 
  select(-INFILE) %>%      # drop the INFILE column
  summarise(across(everything(), mean))

human.result.avg <- dt_all %>%
  group_by(final_categorical) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(frac = n / sum(n)) %>% filter(final_categorical == "2")


model.result.avg$HUMAN <- human.result.avg$frac
Human_denom <- human.result.avg$n


TP_total <- model.result.avg %>% pull(TP.m)
two_thirds_total <- model.result.avg %>% pull(TWOTHIRDS.m)
OP_total <- model.result.avg %>% pull(BR.m)
Luce_total <- model.result.avg %>% pull(LUCE.m)
Human_total <- model.result.avg %>% pull(HUMAN)


plot_prop <- data.frame(
    source = c("TP", "2/3rds", "Optimize", "Luce", "Human"),
    prop = c(TP_total, two_thirds_total, OP_total, Luce_total, Human_total), 
    denom = c(800, 800, 800, 800, Human_denom)
  )

plot_prop$count<-plot_prop$prop * plot_prop$denom


plot_prop<-plot_prop %>% group_by(source) %>% 
  mutate(cilow = prop.test(count,denom)$conf.int[1], 
         cihi = prop.test(count,denom)$conf.int[2])

good_range_low <- plot_prop %>% filter(source == "Human") %>% pull(cilow)
good_range_high <- plot_prop %>% filter(source == "Human") %>% pull(cihi)


### update y-axis
pl <- ggplot(plot_prop, aes(x = reorder(source, prop), y = prop, ymin = cilow, ymax = cihi, color = source, group=source)) + fig_1_single_pane_theme_no_legend() +
  geom_point(size = 18) +
  geom_errorbar(linewidth=3) + 
  scale_color_manual(values = c( BR_pick_second, "gold",  Luce_color, BR_color, TP_color)) + 
  # scale_y_continuous(limits = c(0.58, 1.0)) + 
  ylab("P(Predict Target at Test)")  +
  annotate(geom = "rect", xmin=0, xmax=Inf, ymin=good_range_low, ymax=good_range_high, fill="#7CCD7C", alpha = 0.4) + 
  theme(axis.title.x=element_blank(),
        panel.grid.major = element_line(color = "grey85"),
        panel.grid.minor = element_line(color = "grey95")
  )
if (RUN_LIVE) { pl }
ggsave(plot = pl,
       filename=outputPlot,
       width = 11, height = 11, units = "in")





######################
#Statistical Analyses#
######################

models <- c("TP", "2/3rds", "Optimize", "Luce")

for (model in models) {
  successes <- c(plot_prop %>% filter(source == model) %>% pull(count),
                 plot_prop %>% filter(source == "Human") %>% pull(count))
  trials <- c(plot_prop %>% filter(source == model) %>% pull(denom),
              plot_prop %>% filter(source == "Human") %>% pull(denom))
  sink(outputTable, append = TRUE)
  print(paste(model, "to Humans"))
  print(prop.test(successes, trials))
  sink()
}

for (model in c("TWOTHIRDS.m", "BR.m", "LUCE.m")) {
  successes <- c(df_with_mean_error %>% filter(Measure == model) %>% pull(mean_abs_error),
                 df_with_mean_error %>% filter(Measure == "TP.m") %>% pull(mean_abs_error))
  trials <- c(800, 800)
  sink(outputTable, append = TRUE)
  print(paste(model, "to TP mean error"))
  print(prop.test(successes*800, trials))
  sink()
}

