setwd("~/UNSW/VafaeeLab/bloodbased-pancancer-diagnosis/results_processing/")
library(tidyverse)
library(scmamp)
library(synchrony)
source("../utils/utils.R")
source("metadata.R")


data_info <- read.table('data_info.csv', sep = ',', header = TRUE)
fsm_info <- read.table('fsm_info.csv', sep = ',', header = TRUE)
all_model_results <- read.table('model_results.csv', sep = ',', header = TRUE)

all_model_results <- all_model_results %>%
  mutate(FSM = factor(FSM))

pca_all_model_results <- all_model_results %>%
  filter(grepl('PCA', FSM, fixed = TRUE)) %>%
  select(DataSetId, FSM, Model, Mean_AUC)

t_test_all_model_results <- all_model_results %>%
  filter(grepl('t-test', FSM, fixed = TRUE)) %>%
  select(DataSetId, FSM, Model, Mean_AUC)

wilcoxon_all_model_results <- all_model_results %>%
  filter(grepl('wilcoxon', FSM, fixed = TRUE)) %>%
  select(DataSetId, FSM, Model, Mean_AUC)


analyse_FEM_results <- function(all_model_results, dir_path = "CD", comparison_criteria = "Mean_AUC",
                                dataset_filter = c(), fem_allowed = fem_vector){
  
  all_model_results <- all_model_results %>%
    filter(FSM %in% fem_allowed) %>%
    mutate(FSM = factor(FSM, levels = fem_allowed)) %>%
    mutate(AUC95CIdiff = X95.CI_AUC_upper - X95.CI_AUC_lower)
  
  if (!dir.exists(dir_path)){
    dir.create(dir_path, recursive = TRUE)
  }
  all_model_results <- all_model_results %>%
    select(DataSetId, FSM, Model, comparison_criteria)
  
  if (!(length(dataset_filter) == 0)) {
    all_model_results <- all_model_results %>%
      filter(DataSetId %in% dataset_filter)
  }
  
  for (model in unique(all_model_results$Model)){
    model_results <- all_model_results %>%
      filter(Model == model) %>%
      select(-Model)

    model_results_fsm <- pivot_wider(model_results, names_from = FSM, values_from = comparison_criteria)
    model_results_fsm <- column_to_rownames(model_results_fsm, var = 'DataSetId')

    avg_ranks <- colMeans(rankMatrix(model_results_fsm))

    friedman_test <- friedmanTest(model_results_fsm)

    corrected_friedman_test <- imanDavenportTest(model_results_fsm)

    nemenyi_test <- nemenyiTest(model_results_fsm, alpha=0.05)
    print(nemenyi_test$diff.matrix)

    cd_filename <- paste(model, 'CD.svg', sep = '_')

    plotCD(model_results_fsm, cex = 1)
    title(model)

    dev.copy(svg, filename = get_file_path(cd_filename, dir_path),
             width = 18, height = 5)
    dev.off()

    model_results_dataset <- pivot_wider(model_results, names_from = DataSetId, values_from = comparison_criteria)
    model_results_dataset <- column_to_rownames(model_results_dataset, var = 'FSM')
    print(kendall.w(model_results_dataset))
  }
}


analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/Mean_AUC",
                    comparison_criteria = "Mean_AUC")
analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/AUC95CIdiff",
                    comparison_criteria = "AUC95CIdiff")
analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/X95.CI_AUC_lower",
                    comparison_criteria = "X95.CI_AUC_lower")



analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/filter_compare/Mean_AUC",
                    comparison_criteria = "Mean_AUC",
                    fem_allowed = fem_vector_fil_compare)
analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/filter_compare/AUC95CIdiff",
                    comparison_criteria = "AUC95CIdiff",
                    fem_allowed = fem_vector_fil_compare)
analyse_FEM_results(all_model_results = all_model_results,
                    dir_path = "CD/filter_compare/X95.CI_AUC_lower",
                    comparison_criteria = "X95.CI_AUC_lower",
                    fem_allowed = fem_vector_fil_compare)
