
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

