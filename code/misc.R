
# Library

library(magrittr)
library(pROC)
library(ggplot2)
library(scales)
library(cowplot)

# Pre-processing function

select_data_within_t <- function(data, time_interval, time_var = "diff_time", id_var = "exam_id", sort_time = TRUE){
  
  # Select only one ECG and clinical outcome pair within the corresponding time period.
  
  id_with_follow_up <- table(data[[id_var]])[table(data[[id_var]]) >= 2] %>% names(.)
  
  rownames(data) <- 1:nrow(data)
  remove_row <- NULL
  
  pb <- txtProgressBar(max = length(id_with_follow_up), style = 3)
  for (i in 1:length(id_with_follow_up)){
    
    # Patient-level sub-data
    
    sub_data <- data[data[[id_var]] == id_with_follow_up[i], ]
    
    if (sort_time){
      sub_data <- sub_data[order(sub_data[[time_var]], decreasing = FALSE), ]
    }
    
    # Calculate time difference between each follow-up and select.  
    
    sub_diff_time <- c(sub_data[[time_var]][2:length(sub_data[[time_var]])], NA) - sub_data[[time_var]]
    remove_pos <- which(sub_diff_time < time_interval) + 1
    remove_row <- c(remove_row, rownames(sub_data)[remove_pos])
    
    setTxtProgressBar(pb, i)
  }
  close(pb)
  
  data <- data[-as.numeric(remove_row), ]
  
  return(data)
}

limit_data_outlier <- function(data, min_value, max_value, label_var = "label", 
                               pred_var = "DLM_direct_pred", revise_var = "DLM_dynamic_pred"){
  
  data[data[[label_var]] < min_value, label_var] <- min_value
  data[data[[label_var]] > max_value, label_var] <- max_value
  
  data[which(isTRUE(data[[pred_var]] < min_value)), pred_var] <- min_value
  data[which(isTRUE(data[[pred_var]] > max_value)), pred_var] <- max_value
  
  data[which(isTRUE(data[[revise_var]] < min_value)), revise_var] <- min_value
  data[which(isTRUE(data[[revise_var]] > max_value)), revise_var] <- max_value
  
  return(data)
}

select_follow_up_data <- function(data, follow_up_var = "follow_up"){
  
  data <- data[data[[follow_up_var]] != 0, ]
  
  return(data)
}

# Evaluation functions

get_auroc <- function(cut_point, data, outcome_var, direction, label_var = "label"){
  
  if (direction == "<"){
    response <- (cut_point < data[[label_var]]) + 0L
  } else if (direction == ">"){
    response <- (cut_point > data[[label_var]]) + 0L
  }
  
  roc_result <- roc(response = response, predictor = data[[outcome_var]], direction = direction)

  auc <- as.numeric(roc_result$auc)
  auc_ci <- ci(roc_result)
  
  return(list(auc = auc, ci = auc_ci[3] - auc_ci[1], roc_result = roc_result))
  
}

# Plot functions

process_plot_data <- function(hypok_direct, hypok_dynamic, 
                              hyperk_direct, hyperk_dynamic,
                              lvd_direct, lvd_dynamic){
  
  plot_data <- data.frame(disease = c("hypok", "hypok", "hyperk", "hyperk", "lvd", "lvd"),
                          method = c("DLM (directly)", "DLM (dynamic)", 
                                     "DLM (directly)", "DLM (dynamic)",
                                     "DLM (directly)", "DLM (dynamic)"))
  
  plot_data[,'x'] <- c(1:2, 3.5:4.5, 6:7)
  plot_data[,'y'] <- c(hypok_direct[["auc"]], hypok_dynamic[["auc"]],
                       hyperk_direct[["auc"]], hyperk_dynamic[["auc"]],
                       lvd_direct[["auc"]], lvd_dynamic[["auc"]]) %>% as.numeric(.)
  
  plot_data[,'y_ci'] <- c(hypok_direct[["ci"]], hypok_dynamic[["ci"]],
                          hyperk_direct[["ci"]], hyperk_dynamic[["ci"]],
                          lvd_direct[["ci"]], lvd_dynamic[["ci"]]) %>% as.numeric(.)
  
  plot_data[,'y_low'] <- plot_data[,'y'] - plot_data[,'y_ci'] / 2
  plot_data[,'y_up'] <- plot_data[,'y'] + plot_data[,'y_ci'] / 2
  
  plot_data[,'txt'] <- paste0(formatC(plot_data[,'y'], 3, format = 'f'), 
                              ' (', formatC(plot_data[,'y_low'], 3, format = 'f'), '-', formatC(plot_data[,'y_up'], 3, format = 'f'), ')')
  
  return(plot_data)
}

plot_summary <- function(plot_data, title, y_lab = "AUC"){
  
  col_list <- hue_pal()(10)[c(4, 7)]
  names(col_list) <- c('DLM (directly)', 'DLM (dynamic)')
  
  gg_p <- ggplot(plot_data, aes(x = x, y = y, fill = method)) +
          geom_bar(stat = "identity") +
          geom_errorbar(aes(ymin = y_low, ymax = y_up), width = .4, position = position_dodge(.9)) +
          
          scale_y_continuous(limits = c(0, 1.97), 
                             breaks = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6) * 1.65, 
                             labels = function(x){(c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6) + 0.4) %>% sprintf("%.1f", .)}) +
          scale_x_continuous(name = '', breaks = plot_data[,'x'] - 0.15, 
                             labels = plot_data[['method']], limits = c(0.5, 7.5)) + 
          
          ggtitle(title) +
          xlab('') + 
          ylab(y_lab) + 
          
          scale_fill_manual(values = col_list) +
          
          annotate(geom = "text", 
                   x = plot_data[,'x'], y = 1.52,
                   label = plot_data[,'txt'], size = 5, color = "black", angle = 90, fontface = 2) +
          
          annotate(geom = "line", x = c(0.5, 2.5), y = c(1.88, 1.88), size = 1) +
          annotate(geom = "text", x = 1.5, y = 1.96, label = 'Hypokalemia', size = 4.1, fontface = 2) +
          
          annotate(geom = "line", x = c(3, 5), y = c(1.88, 1.88), size = 1) +
          annotate(geom = "text", x = 4, y = 1.96, label = 'Hyperkalemia', size = 4.1, fontface = 2) +
          
          annotate(geom = "line", x = c(5.5, 7.5), y = c(1.88, 1.88), size = 1) +
          annotate(geom = "text", x = 6.5, y = 1.96, label = 'LVD', size = 4.1, fontface = 2) +
          
          theme_minimal() +
          theme(plot.title = element_text(color = "#000000", size = 16, face = "bold.italic"),
                legend.position = "none",
                panel.border = element_blank(),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                panel.background = element_blank(),
                axis.ticks.x = element_blank(),
                axis.ticks.y = element_blank(),
                axis.title.y = element_text(size = 12, face = "bold"),
                axis.text.x = element_text(angle = 90, hjust = 1, size = 14, face = "bold"),
                axis.text.y = element_text(angle = 0, hjust = 1, size = 12, face = "bold"))
  
  return(gg_p)
}

add_significant <- function(gg_p, plot_data, p_value, disease_var){
  
  if (p_value < 0.05){
    
    x1 <- plot_data[plot_data[["disease"]] == disease_var & plot_data[["method"]] == "DLM (directly)", "x"]
    x2 <- plot_data[plot_data[["disease"]] == disease_var & plot_data[["method"]] == "DLM (dynamic)", "x"]
    
    y1 <- max(plot_data[plot_data[["disease"]] == disease_var, "y_up"]) + 0.1
    y2 <- y1 + 0.02 * 2
    
    gg_p <- gg_p + 
      annotate(geom = "line", x = c(x1, x1), y = c(y1, y2), size = 0.8) +
      annotate(geom = "line", x = c(x1, x2), y = c(y2, y2), size = 0.8) +
      annotate(geom = "line", x = c(x2, x2), y = c(y1, y2), size = 0.8) +
      annotate(geom = "text", x = mean(c(x1, x2)), y = mean(c(y1, y2)) + 0.020 * 1.5, label = '*', size = 8, fontface = 2)
    
  }
  
  return(gg_p)
}





