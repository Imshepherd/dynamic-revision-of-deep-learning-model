# Dynamic Revision of Deep Learning Model

Dynamic revision of deep learning model (DLM) is a method that use personal pre-annotated electrocardiograms (ECGs) for enhancing the accuracy in patients with multiple visits. This repository contains de-identified data and code for the two parts of this method. The first part is to construct the linear mixed model (LMM) to obtain the parameters for the dynamic revision. The second part is the dynamic revision of DLM prediction, which is illustrated as below:<br>

![procedure_of_blup](https://github.com/Imshepherd/dynamic-revision-of-deep-learning-model/blob/main/docs/images/procedure_of_blup.png "Procedure of BLUP")

The DLM predictions via ECGs is revised with the personal best linear unbiased prediction (BLUP) on follow-up ECGs. The personal BLUP is calculated by the parameters from LMMs, the previous DLM predictions, and the corresponding ground truth. The black box indicated the dynamic revision of DLM prediction. The detail of method and results are presented in:<br>

  * YS Lou and C Lin, "Dynamic deep learning algorithm prediction for patients with multiple visits in electrocardiogram analysis", submitted to journal in November 2021.
    
# Requirements

  * [R](https://www.r-project.org/) and [Rstudio (not necessary)](https://www.rstudio.com/)
  * [lme4](https://cran.r-project.org/web/packages/lme4/index.html)

You need to have `lme4` and its dependencies installed to construct LMM. You can install `lme4` by running the following line in your R console:

```R
install.packages("lme4", dependencies = TRUE)
```    

# Usage

The example code can be found in ['code/dynamic_revision.R'](https://github.com/Imshepherd/dynamic-revision-of-deep-learning-model/blob/main/code/dynamic_revision.R), and the performance is summarized as following:

The function of constructing LMM, calculating BLUP, and dynamic revision can be found in ['code/personal_blup.R'](https://github.com/Imshepherd/dynamic-revision-of-deep-learning-model/blob/main/code/personal_blup.R).
  
# Example data
  
  
  
  
# How to cite

If you use this code in your work, please cite.
  
    