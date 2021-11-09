
# Library

source('code/misc.R')
source('code/personal_blup.R')

# Settings

options(stringsAsFactors = FALSE)

time_interval <- list(k = 2, ef = 14 * 24)
value_range <- list(k = list(min = 1.5, max = 7.5), ef = list(min = 10, max = 90))
disease_cut <- list(hypok = 3.5, hyperk = 5.5, lvd = 35)

# Read data

k_data <- read.csv("data/serum_potassium_data.csv")
ef_data <- read.csv("data/ejection_fraction_data.csv")

# Split development samples and validation sample

k_dev_sample <- k_data[k_data[["dataset"]] %in% c("development", "tuning"), ]
ef_dev_sample <- ef_data[ef_data[["dataset"]] %in% c("development", "tuning"), ]

k_in_valid <- k_data[k_data$dataset == "internal_validation", ]
k_ex_valid <- k_data[k_data$dataset == "external_validation", ]

ef_in_valid <- ef_data[ef_data$dataset == "internal_validation", ]
ef_ex_valid <- ef_data[ef_data$dataset == "external_validation", ]

# Pre-process the development samples in development and tuning set

k_subdata <- select_data_within_t(k_dev_sample, time_interval[["k"]])
ef_subdata <- select_data_within_t(ef_dev_sample, time_interval[["ef"]])

# Construct linear mixed model (LMM) with sample in tuning set

k_tuning <- k_subdata[k_subdata$dataset == "tuning", ]
ef_tuning <- ef_subdata[ef_subdata$dataset == "tuning", ]

k_lmm <- construct_lmm(k_tuning)
ef_lmm <- construct_lmm(ef_tuning)

# Dynamically revise the prediction of serum potassium in internal and external validation set

k_in_valid <- dyna_revise_using_blup(k_in_valid, k_lmm)
k_ex_valid <- dyna_revise_using_blup(k_ex_valid, k_lmm)

# Dynamically revise the prediction of ejection fraction in internal and external validation set

ef_in_valid <- dyna_revise_using_blup(ef_in_valid, ef_lmm)
ef_ex_valid <- dyna_revise_using_blup(ef_ex_valid, ef_lmm)

# Pre-process for evaluation

k_in_valid <- limit_data_outlier(k_in_valid, value_range[["k"]][["min"]], value_range[["k"]][["max"]])
k_ex_valid <- limit_data_outlier(k_ex_valid, value_range[["k"]][["min"]], value_range[["k"]][["max"]])

ef_in_valid <- limit_data_outlier(ef_in_valid, value_range[["ef"]][["min"]], value_range[["ef"]][["max"]])
ef_ex_valid <- limit_data_outlier(ef_ex_valid, value_range[["ef"]][["min"]], value_range[["ef"]][["max"]])

# Select the follow-up sample

k_in_valid <- select_follow_up_data(k_in_valid)
k_ex_valid <- select_follow_up_data(k_ex_valid)

ef_in_valid <- select_follow_up_data(ef_in_valid)
ef_ex_valid <- select_follow_up_data(ef_ex_valid)

# Evaluate the performance for diagnosing hypokalemia, hyperkalemia, and left ventricular dysfunction (LVD)

hypok_in_direct <- get_auroc(disease_cut[["hypok"]], k_in_valid, "DLM_direct_pred", direction = "<")
hypok_in_dynamic <- get_auroc(disease_cut[["hypok"]], k_in_valid, "DLM_dynamic_pred", direction = "<")

hypok_ex_direct <- get_auroc(disease_cut[["hypok"]], k_ex_valid, "DLM_direct_pred", direction = "<")
hypok_ex_dynamic <- get_auroc(disease_cut[["hypok"]], k_ex_valid, "DLM_dynamic_pred", direction = "<")

hyperk_in_direct <- get_auroc(disease_cut[["hyperk"]], k_in_valid, "DLM_direct_pred", direction = ">")
hyperk_in_dynamic <- get_auroc(disease_cut[["hyperk"]], k_in_valid, "DLM_dynamic_pred", direction = ">")

hyperk_ex_direct <- get_auroc(disease_cut[["hyperk"]], k_ex_valid, "DLM_direct_pred", direction = ">")
hyperk_ex_dynamic <- get_auroc(disease_cut[["hyperk"]], k_ex_valid, "DLM_dynamic_pred", direction = ">")

lvd_in_direct <- get_auroc(disease_cut[["lvd"]], ef_in_valid, "DLM_direct_pred", direction = "<")
lvd_in_dynamic <- get_auroc(disease_cut[["lvd"]], ef_in_valid, "DLM_dynamic_pred", direction = "<")

lvd_ex_direct <- get_auroc(disease_cut[["lvd"]], ef_ex_valid, "DLM_direct_pred", direction = "<")
lvd_ex_dynamic <- get_auroc(disease_cut[["lvd"]], ef_ex_valid, "DLM_dynamic_pred", direction = "<")

# Compare AUC

hypok_in_p <- roc.test(hypok_in_direct[["roc_result"]], hypok_in_dynamic[["roc_result"]])[["p.value"]]
hypok_ex_p <- roc.test(hypok_ex_direct[["roc_result"]], hypok_ex_dynamic[["roc_result"]])[["p.value"]]
  
hyperk_in_p <- roc.test(hyperk_in_direct[["roc_result"]], hyperk_in_dynamic[["roc_result"]])[["p.value"]]
hyperk_ex_p <- roc.test(hyperk_ex_direct[["roc_result"]], hyperk_ex_dynamic[["roc_result"]])[["p.value"]]
  
lvd_in_p <- roc.test(lvd_in_direct[["roc_result"]], lvd_in_dynamic[["roc_result"]])[["p.value"]]
lvd_ex_p <- roc.test(lvd_ex_direct[["roc_result"]], lvd_ex_dynamic[["roc_result"]])[["p.value"]]

# Pre-process plot data in internal and external validation set

plot_data_in <- process_plot_data(hypok_in_direct, hypok_in_dynamic, 
                                  hyperk_in_direct, hyperk_in_dynamic,
                                  lvd_in_direct, lvd_in_dynamic)

plot_data_ex <- process_plot_data(hypok_ex_direct, hypok_ex_dynamic, 
                                  hyperk_ex_direct, hyperk_ex_dynamic,
                                  lvd_ex_direct, lvd_ex_dynamic)

# Plot the performance in internal and external validation set

gg_p_in <- plot_summary(plot_data_in, "Internal validation set")
gg_p_ex <- plot_summary(plot_data_ex, "External validation set")

# Plot significant line in internal and external validation set

gg_p_in <- plot_significant(gg_p_in, plot_data_in, hypok_in_p, "hypok")
gg_p_in <- plot_significant(gg_p_in, plot_data_in, hyperk_in_p, "hyperk")
gg_p_in <- plot_significant(gg_p_in, plot_data_in, lvd_in_p, "lvd")

gg_p_ex <- plot_significant(gg_p_ex, plot_data_ex, hypok_in_p, "hypok")
gg_p_ex <- plot_significant(gg_p_ex, plot_data_ex, hyperk_in_p, "hyperk")
gg_p_ex <- plot_significant(gg_p_ex, plot_data_ex, lvd_in_p, "lvd")

# Merge plots and export figure

final_p <- ggdraw()
final_p <- final_p + draw_plot(gg_p_in, x = 0.000 + 0.027, y = 0, width = 0.465, height = 1)
final_p <- final_p + draw_plot(gg_p_ex, x = 0.490 + 0.027, y = 0, width = 0.465, height = 1)

print(final_p)
dev.print(file = "docs/images/summary_of_performance.png", 
          device = png, width = 840, height = 700)
# dev.off()


