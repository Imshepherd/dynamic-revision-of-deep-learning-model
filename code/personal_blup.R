
# Library

library(magrittr)
library(lme4)

# Personal BLUP functions

construct_lmm <- function(data, id_var = "exam_id", label_var = "label", dl_pred_var = "DLM_direct_pred"){
  
  # Each patient must has at least two sample for constructing LMM.
  
  id_with_follow_up <- table(data[[id_var]])[table(data[[id_var]]) >= 2] %>% names(.)
  data <- data[data[[id_var]] %in% id_with_follow_up, ]
  
  sub_formula <- as.formula(paste0(label_var, " ~ ", dl_pred_var, " + ( ", dl_pred_var, " | ", id_var, ")"))
  lmm_model <- lmer(sub_formula, data = data)
  
  return(lmm_model)
}

dyna_revise_using_blup <- function(data, lmm_model, 
                                   id_var = "exam_id", pred_var = "DLM_direct_pred", 
                                   label_var = "label", time_var = "diff_time", revise_var = "DLM_dynamic_pred", sort_time = TRUE){
  
  # Get parameter from LMM
  
  varcor_G <- c(as.numeric(VarCorr(lmm_model)[[1]]))
  varcor_G_dim <- sqrt(length(varcor_G))
  G <- matrix(varcor_G, varcor_G_dim, varcor_G_dim)
  
  sigma_square <- sigma(lmm_model)^2
  
  fixed_B <- matrix(c(fixef(lmm_model)), ncol = 1)
  
  # Declare index and output vector
  
  rownames(data) <- 1:nrow(data)
  blup_modify <- rep(NA, length = nrow(data))

  uni_id <- unique(data[[id_var]])
  
  pb <- txtProgressBar(max = length(uni_id), style = 3)
  for (i in 1:length(uni_id)){
    
    # Patient-level sub-data
    
    sub_data <- data[data[[id_var]] == uni_id[i], ]
    
    if (nrow(sub_data) >= 2){
      
      if (sort_time){
        sub_data <- sub_data[order(sub_data[[time_var]], decreasing = FALSE), ]
      }
      
      # Add intercept
      
      X_all <- cbind(1, sub_data[,, drop = FALSE]) 
      
      for (j in 2:nrow(X_all)){
        
        # Dynamic revised on follow_up data.
        # Get previous predictions
        
        X <- X_all[1:(j-1), c('1', pred_var), drop = FALSE] %>% as.matrix(.)
        Z <- X_all[1:(j-1), c('1', pred_var), drop = FALSE] %>% as.matrix(.)
        
        # Calculate personal variance co-variance sigma matrix
        
        R <- matrix(0, nrow(Z), nrow(Z))
        diag(R) <- sigma_square
        
        varcor_sigma <- Z %*% G %*% t(Z) + R
        
        # Get previous corresponding labels
        
        Y <- X_all[1:(j-1), label_var, drop = FALSE] %>% as.matrix(.)
        
        # Get personal BLUP
        
        BLUP <- G %*% t(Z) %*% solve(varcor_sigma) %*% (Y - X %*% fixed_B)
        
        # Merge fixed variable and random variable
        
        specific_B <- fixed_B + BLUP
        
        # Revise prediction on current follow-up data
        
        new_pred_Y <- (X_all[j, c('1', pred_var), drop = FALSE] %>% as.matrix(.)) %*% specific_B
        blup_modify[as.numeric(rownames(X_all)[j])] <- new_pred_Y
      }
    } 
    
    setTxtProgressBar(pb, i)
  }
  close(pb)
  
  data[[revise_var]] <- blup_modify
  
  return(data)
}


