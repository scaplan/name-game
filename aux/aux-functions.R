
#############################
#############################
#############################

frequire <- require
require <- function(...) suppressPackageStartupMessages(frequire(...))


## Helper function for loading / installing required packages
ensure_package <- function(pkg) {
  if (require(pkg, character.only = TRUE)) {
    # print(paste(pkg, "is loaded correctly"))
  } else {
    
    # Try to install the package
    message(paste("Trying to install", pkg))
    install.packages(pkg, dependencies = TRUE)
    
    # Try loading the package again
    if (require(pkg, character.only = TRUE)) {
      message(paste(pkg, "installed and loaded"))
    } else {
      stop(paste("Could not install", pkg))
    }
    
  }
}




#############################
###   Shared Variables    ###
#############################

PAPER_LIST <<- c("CB2015", "CBBB2018")

read_ng_filter_confed <<- function(input_path, run_live) { 
  ng_data <- read.csv(input_path, stringsAsFactors = T,header=TRUE, sep = "\t") # Read in the target words for each instance
  
  if (run_live) { message(nrow(ng_data)) } # check num rows before and after filtering
  ng_data <- ng_data %>% filter(IsConfed == "FALSE")
  if (run_live) {message(nrow(ng_data)) } # check num rows before and after filtering
  return(ng_data)
}

sink_vars <<- function(var_names, file_name, doAppend = FALSE) {
  sink(file_name, append = doAppend)
  # Loop through each variable name in the character vector
  for (var_name in var_names) {
    cat(var_name, ":\n")
    # Retrieve and print the value of the variable
    if (exists(var_name, envir = .GlobalEnv)) {
      print(get(var_name, envir = .GlobalEnv))
    } else {
      cat("Variable does not exist.\n")
    }
    cat("\n")
  }
  sink() # Stop sinking at the end before returning
}

get_accuracy_by_round_by_source <<- function(df, model.name, SplitSource) {
  model.deterministic <- paste(model.name, ".deterministic", sep="")
  correct <- paste("Correct.", model.name, sep="")
  score <- paste(model.name, ".score", sep="")
  
  if(missing(SplitSource)) {
    results.byround <- df %>%
      group_by(!!sym(model.deterministic), RoundNum) %>% 
      summarise(Total = n(),
                !!sym(correct) :=  sum(as.numeric(eval(as.name(score)))),
                Accuracy = eval(as.name(correct))/Total, .groups = "drop_last") %>%
      filter(!!sym(model.deterministic) == "True") %>%
      subset(select=-c(eval(as.name(model.deterministic)), eval(as.name(correct)))) %>%
      mutate(Model = model.name)
  } else {
    results.byround <- df %>%
      group_by(!!sym(model.deterministic), SourcePaper, RoundNum) %>% 
      summarise(Total = n(),
                !!sym(correct) :=  sum(as.numeric(eval(as.name(score)))),
                Accuracy = eval(as.name(correct))/Total, .groups = "drop_last") %>%
      filter(!!sym(model.deterministic) == "True") %>%
      subset(select=-c(eval(as.name(model.deterministic)), eval(as.name(correct)))) %>%
      mutate(Model = model.name)
  }
  return(results.byround)
}

get_accuracy_by_round_with_stochastic <<- function(df, model.name, SplitSource) {
  correct <- paste("Correct.", model.name, sep="")
  score <- paste(model.name, ".score", sep="")
  
  if(missing(SplitSource)) {
    results.byround <- df %>%
      group_by(RoundNum) %>% 
      summarise(Total = n(),
                !!sym(correct) :=  sum(as.numeric(eval(as.name(score)))),
                Accuracy = eval(as.name(correct))/Total, .groups = "drop_last") %>%
      subset(select=-c(eval(as.name(correct)))) %>%
      mutate(Model = model.name)
  } else {
    results.byround <- df %>%
      group_by(SourcePaper, RoundNum) %>% 
      summarise(Total = n(),
                !!sym(correct) :=  sum(as.numeric(eval(as.name(score)))),
                Accuracy = eval(as.name(correct))/Total, .groups = "drop_last") %>%
      subset(select=-c(eval(as.name(correct)))) %>%
      mutate(Model = model.name)
  }
  return(results.byround)
}


#############################
### Plot Theme Aesthetics ###
#############################

load_in_plot_aesthetics <- function(x) {
  
  
  # If errorbars overlap use position_dodge to shift them horizontally
  pd <<- position_dodge(0.2)
  
  # use fixed color for BR, TP, CB, and Non-prod
  TP_color <<- "dodgerblue"
  BR_color <<- "red"
  CB_color <<- "forestgreen"
  Luce_color <<- "grey"
  BRnonprod_color <<- "red4"
  BR_pick_second <<- "purple4"
  
  memory_color <<- "grey31"
  name_color <<- "orange3"
  
  four_model_color <<- function() {
    scale_color_manual(values = c("Optimize" = BR_color,
                                  "Optimize (pre-TP)" = BRnonprod_color,
                                  "Imitate" = CB_color,
                                  "Threshold (TP)" = TP_color))
  }
  
  five_model_color <<- function() {
    scale_color_manual(values = c("Optimize" = BR_color,
                                  "Optimize (pre-TP)" = BRnonprod_color,
                                  "Imitate" = CB_color,
                                  "Luce (post-TP)" = Luce_color,
                                  "Threshold (TP)" = TP_color))
  }
  
  four_model_color_luce_simple <<- function() {
    scale_color_manual(values = c("Optimize" = BR_color,
                                  "Imitate" = CB_color,
                                  "Luce" = Luce_color,
                                  "Threshold (TP)" = TP_color))
  }
  
  four_model_shape <<- function() {
    scale_shape_manual(values = c("Optimize" = 16,
                                  "Optimize (pre-TP)" = 14,
                                  "Imitate" = 17,
                                  "Threshold (TP)" = 18))
  }
  
  five_model_shape <<- function() {
    scale_shape_manual(values = c("Optimize" = 16,
                                  "Optimize (pre-TP)" = 14,
                                  "Imitate" = 17,
                                  "Luce (post-TP)" = 15,
                                  "Threshold (TP)" = 18))
  }
  
  four_model_shape_luce_simple <<- function() {
    scale_shape_manual(values = c("Optimize" = 16,
                                  "Imitate" = 17,
                                  "Luce" = 15,
                                  "Threshold (TP)" = 18))
  }
  
  
  TP_vs_nonprod_two_set_color <<- function() {
    scale_color_manual(values = c("TP" = TP_color,
                                  "BRnonprod" = BRnonprod_color))
  }
  
  TPBR_vs_CB_two_set_color <<- function() {
    scale_color_manual(values = c("TP/BR" = TP_color,
                                  "CB" = CB_color))
  }
  
  
  axisTextSizeBig <<- 30
  axisTextSize <<- 24
  axisTextSizeSmall <<- 16
  lineSize <<- 2
  dotSize <<- 8
  density_plot_ymax <<- 0.3
  
  
  single_pane_theme <<- function() { 
    theme_minimal() %+replace% 
      theme(legend.position="right",
            legend.title = element_text(size=axisTextSize,face="bold"),
            legend.text=element_text(size=axisTextSize,face="bold"),
            plot.title = element_text(hjust = 0.5,size=axisTextSize,face="bold"),
            axis.text=element_text(size=axisTextSize,face="bold"),
            axis.text.x=element_text(size=axisTextSize,face="bold"),
            axis.text.y=element_text(size=axisTextSize,face="bold"),
            axis.title.x = element_text(size=axisTextSize,face="bold"),
            axis.title.y = element_text(size=axisTextSize,face="bold", angle = 90),
            strip.text = element_text(size=axisTextSize,face="bold"),
            axis.line = element_line(colour = "black"),
            panel.border = element_rect(colour = "black", fill=NA, linewidth=1)
      )
  }
  
  single_pane_theme_withLegend <<- function(legend_position) { 
    theme_minimal() %+replace% 
      theme(legend.position = "inside", legend.position.inside =  legend_position,
            legend.title = element_text(size=axisTextSize,face="bold"),
            legend.text=element_text(size=axisTextSize,face="bold"),
            plot.title = element_text(hjust = 0.5,size=axisTextSize,face="bold"),
            axis.text=element_text(size=axisTextSize,face="bold"),
            axis.text.x=element_text(size=axisTextSize,face="bold"),
            axis.text.y=element_text(size=axisTextSize,face="bold"),
            axis.title.x = element_text(size=axisTextSize,face="bold"),
            axis.title.y = element_text(size=axisTextSize,face="bold", angle = 90),
            axis.line = element_line(colour = "black"),
            panel.border = element_rect(colour = "black", fill=NA,linewidth=1)
      )
  }
  
  fig_1_single_pane_theme <<- function(legend_position) {
    theme_bw() %+replace% 
      theme(legend.title=element_blank(), legend.position = "inside",
            legend.position.inside =  legend_position,
            legend.box.background = element_rect(colour = "black",fill="white", linewidth=1.4),
            legend.text=element_text(size=axisTextSizeBig),
            axis.title.x=element_text(size=axisTextSizeBig),
            axis.title.y=element_text(size=axisTextSizeBig, angle = 90),
            plot.title=element_text(size=axisTextSizeBig, hjust=0.5),
            axis.text.x=element_text(size = axisTextSizeBig, vjust=0.8),
            axis.text.y=element_text(size = axisTextSizeBig),
            panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_line(colour = "black"))
  }
  
  fig_1_single_pane_theme_no_legend <<- function(legend_position) {
    theme_bw() %+replace% 
      theme(
            legend.position="none",
            axis.title.x=element_text(size=axisTextSizeBig),
            axis.title.y=element_text(size=axisTextSizeBig, angle = 90),
            plot.title=element_text(size=axisTextSizeBig, hjust=0.5),
            axis.text.x=element_text(size = axisTextSizeBig, vjust=0.8),
            axis.text.y=element_text(size = axisTextSizeBig),
            panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_line(colour = "black"))
  }

}




load_in_libraries <- function(x) {
  
  # Could in future split these up into plotting vs. non-plotting libraries
  # Or more modular division
  
  packages <- c("dplyr",
                "tidyr",
                "ggplot2",
                "Hmisc",
                "scales",
                "Matrix",
                "tibble",
                "lme4",
                "reshape2",
                "tidyverse",
                "cowplot",
                "ggpubr",
                "ggrepel",
                "xtable")
  
  # Loop over each package and call ensure_package
  for (pkg in packages) {
    ensure_package(pkg)
  }
  
  return("load_in_libraries correctly")
  # print("load_in_libraries correctly")
}

#############################
#############################
#############################