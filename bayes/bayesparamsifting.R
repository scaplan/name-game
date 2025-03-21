
###########################################################
###########################################################
##  Author: Spencer Caplan
##  CUNY Graduate Center
##
##  Parameter search for Bayesian simulation
###########################################################
###########################################################


rm(list = ls(all.names = TRUE)) # clear all objects includes hidden objects.
invisible(gc()) # free up memory and report the memory usage.
cat("Parameter search for Bayes tipping point simulation...")
pdf(NULL)

## For handling project structure / relative paths ##
suppressMessages(require("rprojroot"))
sourceDir <- find_root(is_git_root)
source(file.path(sourceDir, "aux", "aux-functions.R"))



args = commandArgs(trailingOnly=TRUE)
RUN_LIVE <- interactive()

if (!RUN_LIVE) {
  if (length(args) == 2) {
    dataDir = args[1]
    targetInputFile = args[2]
  } else {
    print("Incorrect number of input arguments! Exiting now...")
    stop("Incorrect number of input arguments")
  }
  
} else {
  currMachine <- Sys.info()[['nodename']]
  dataDir = paste(sourceDir, '/output/bayestippingpoint/', sep = "")
  targetInputFile <- "bayes_tipping_point_simulation_summary.csv"
}

setwd(sourceDir)
output_message <- load_in_libraries()
load_in_plot_aesthetics()




##################################
## 0. Reading in data 
setwd(dataDir)
bayes_data <- read.csv(targetInputFile, stringsAsFactors = T,header=TRUE, sep = ",") # Read in the target words for each instance

bayes_data <- bayes_data %>%
  mutate(PRIOR_SCALAR = paste(PRIOR, UPDATE_SCALAR)) %>%
  select(-PRIOR, -UPDATE_SCALAR)



##################################
## 1. Confirm that tipping round varies by network size.

bd.plotting <- bayes_data %>%
  mutate(PRIOR_SCALAR_CONFED = paste(PRIOR_SCALAR, CONFED_PROP)) %>%
  select(-PRIOR_SCALAR, -CONFED_PROP) %>%
  mutate(TIPPED = ifelse(FIRST_TIPPED < 1000, 1, 0))


db.tip.likelihood <- bd.plotting %>%  group_by(NETWORK_SIZE) %>%
  summarise(n = n(),
            TIP_AVG = mean(TIPPED), .groups = "drop_last")
# Across 2016 parameter configurations NETWORK_SIZE is positively correlated with tipping
write.table(db.tip.likelihood, file="tippinglikelihoodbynetworksize.tsv", quote=FALSE, sep='\t', row.names = FALSE)

# Prop-test
Tip.time.96 <- db.tip.likelihood %>% subset(NETWORK_SIZE == 96) %>% pull(TIP_AVG)
Tip.time.24 <- db.tip.likelihood %>% subset(NETWORK_SIZE == 24) %>% pull(TIP_AVG)
size = db.tip.likelihood %>% subset(NETWORK_SIZE == 96) %>% pull(n)
# prop.test(x = c(Tip.time.96*size, Tip.time.24*size), n = c(size, size), conf.level = 0.95, correct = TRUE)


# And even within the simulations that did tip within 70 rounds, there is 
# still a positive correlation between network size and speed of tipping
db.tip.speed <- bd.plotting %>% filter(TIPPED == 1) %>%  group_by(NETWORK_SIZE) %>%
  summarise(n = n(),
            TIPPING_ROUND = mean(FIRST_TIPPED), .groups = "drop_last")
write.table(db.tip.speed, file="tippingspeedbynetworksize.tsv", quote=FALSE, sep='\t', row.names = FALSE)




##################################
## 2. Then show there's no single parameter configuration that works across the board

if (RUN_LIVE) { nrow(bayes_data) }
starting_size <- nrow(bayes_data)
# first remove any parameter settings which tip too early (7 rounds or fewer)
bayes_data.filtered <- bayes_data %>% filter(FIRST_TIPPED > 8)
if (RUN_LIVE) { nrow(bayes_data.filtered) }
num_dropped <- starting_size - nrow(bayes_data.filtered)
if (RUN_LIVE) { num_dropped }

# then remove any parameter settings which tip with too few confed
starting_size <- nrow(bayes_data.filtered)
bayes_data.filtered <- bayes_data.filtered %>% filter(CONFED_PROP > 0.2 | (CONFED_PROP <= 0.2 & FIRST_TIPPED == 1000))
if (RUN_LIVE) { nrow(bayes_data.filtered) }
num_dropped <- starting_size - nrow(bayes_data.filtered)
if (RUN_LIVE) { num_dropped }

# then remove any parameter settings which never tip (or tip less than half the time), even though confed_prop is >= 0.25
starting_size <- nrow(bayes_data.filtered)
bayes_data.filtered <- bayes_data.filtered %>% filter(CONFED_PROP < 0.25 | (CONFED_PROP >= 0.25 & FIRST_TIPPED < 700))
if (RUN_LIVE) { nrow(bayes_data.filtered) }
num_dropped <- starting_size - nrow(bayes_data.filtered)
if (RUN_LIVE) { num_dropped }


# Then convert to wide format, and remove any NA rows
bd.wide <- pivot_wider(bayes_data.filtered, names_from = c(NETWORK_SIZE, CONFED_PROP), values_from = FIRST_TIPPED)
if (RUN_LIVE) { nrow(bd.wide) }

write.table(bd.wide, file="nobayesparamconfigs.tsv", quote=FALSE, sep='\t', row.names = FALSE)


# finally remove any NA values (since those param configs got filtered some one network size but not another)
bd.wide.complete <- bd.wide %>% filter(complete.cases(.))
if (RUN_LIVE) { 
  nrow(bd.wide.complete)
  View(bd.wide.complete)
}



