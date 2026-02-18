# ============================================================
# METADATA HARMONIZATION VALIDATION TESTS
# ============================================================

library(readr)
library(readxl)
library(dplyr)

# ============================================================
# CONFIGURATION
# ============================================================

dataset_files <- list(
  TCGA_SKCM = "TCGA_SKCM.csv",
  Riaz      = "Riaz.csv",
  Ribas     = "Ribas.csv",
  Liu       = "Liu.csv",
  Hugo      = "Hugo.csv",
  Gide      = "Gide.csv",
  Cam121    = "Cam121.csv",
  Helmink   = "Helmink.csv"
)
setwd("./Melanoma/Metadata/")
mapping_file <- "./SKCM_column_mapping_guide.xlsx"
harmonized_file <- "SKCM_harmonized_metadata_V2_020526.csv"

# ============================================================
# TEST FUNCTIONS
# ============================================================

### Test 1: Row count preservation
test_row_counts <- function(dataset_files, harmonized_file) {
  cat("\n=== TEST 1: Row Count Preservation ===\n")
  
  harmonized <- read_csv(harmonized_file, show_col_types = FALSE)
  
  results <- data.frame(
    Dataset = character(),
    Original_Rows = integer(),
    Harmonized_Rows = integer(),
    Match = logical(),
    stringsAsFactors = FALSE
  )
  
  for (dataset_name in names(dataset_files)) {
    file_path <- dataset_files[[dataset_name]]
    if (!file.exists(file_path)) next
    
    original <- if (grepl("\\.csv$", file_path)) {
      read_csv(file_path, show_col_types = FALSE)
    } else {
      read_excel(file_path)
    }
    
    harmonized_subset <- harmonized[harmonized$DATASET == dataset_name, ]
    
    match <- nrow(original) == nrow(harmonized_subset)
    
    results <- rbind(results, data.frame(
      Dataset = dataset_name,
      Original_Rows = nrow(original),
      Harmonized_Rows = nrow(harmonized_subset),
      Match = match,
      stringsAsFactors = FALSE
    ))
    
    if (!match) {
      cat(sprintf("  ⚠ WARNING: %s has %d original rows but %d harmonized rows\n",
                  dataset_name, nrow(original), nrow(harmonized_subset)))
    }
  }
  
  print(results)
  
  all_match <- all(results$Match)
  if (all_match) {
    cat("  ✓ PASS: All datasets have matching row counts\n")
  } else {
    cat("  ✗ FAIL: Some datasets have mismatched row counts\n")
  }
  
  return(results)
}

### Test 2: Spot check specific columns for a dataset
test_column_mapping <- function(dataset_name, dataset_file, mapping_file, harmonized_file,
                                columns_to_check = c("TIME_TO_DEATH_DAYS", "OS_MONTHS", "TIME_TO_LAST_FOLLOWUP_DAYS")) {
  
  cat(sprintf("\n=== TEST 2: Column Mapping for %s ===\n", dataset_name))
  
  # Load files
  original <- if (grepl("\\.csv$", dataset_file)) {
    read_csv(dataset_file, show_col_types = FALSE)
  } else {
    read_excel(dataset_file)
  }
  
  harmonized <- read_csv(harmonized_file, show_col_types = FALSE)
  harmonized_subset <- harmonized[harmonized$DATASET == dataset_name, ]
  
  mapping_guide <- read_excel(mapping_file)
  
  # For each column to check
  for (std_col in columns_to_check) {
    cat(sprintf("\n--- Checking: %s ---\n", std_col))
    
    # Find original column name from mapping
    std_col_idx <- which(mapping_guide$STANDARD_COLUMN_NAMES == std_col)
    if (length(std_col_idx) == 0) {
      cat(sprintf("  ⚠ Column %s not found in mapping guide\n", std_col))
      next
    }
    
    orig_col_name <- as.character(mapping_guide[[dataset_name]][std_col_idx])
    
    if (is.na(orig_col_name) || orig_col_name == "") {
      cat(sprintf("  ℹ No mapping for %s in %s\n", std_col, dataset_name))
      next
    }
    
    if (!(orig_col_name %in% names(original))) {
      cat(sprintf("  ⚠ Original column '%s' not found in dataset\n", orig_col_name))
      next
    }
    
    # Compare values (handle potential unit conversions)
    orig_vals <- original[[orig_col_name]]
    harm_vals <- harmonized_subset[[std_col]]
    
    # Basic stats comparison
    cat(sprintf("  Original column: %s\n", orig_col_name))
    cat(sprintf("    Non-NA values: %d\n", sum(!is.na(orig_vals))))
    cat(sprintf("    Range: %.2f - %.2f\n", min(orig_vals, na.rm = TRUE), max(orig_vals, na.rm = TRUE)))
    cat(sprintf("    Mean: %.2f\n", mean(orig_vals, na.rm = TRUE)))
    
    cat(sprintf("  Harmonized column: %s\n", std_col))
    cat(sprintf("    Non-NA values: %d\n", sum(!is.na(harm_vals))))
    cat(sprintf("    Range: %.2f - %.2f\n", min(harm_vals, na.rm = TRUE), max(harm_vals, na.rm = TRUE)))
    cat(sprintf("    Mean: %.2f\n", mean(harm_vals, na.rm = TRUE)))
    
    # Sample comparison (first 5 non-NA values)
    non_na_idx <- which(!is.na(orig_vals))[1:min(5, sum(!is.na(orig_vals)))]
    if (length(non_na_idx) > 0) {
      cat("\n  Sample values:\n")
      comparison <- data.frame(
        Index = non_na_idx,
        Original = orig_vals[non_na_idx],
        Harmonized = harm_vals[non_na_idx],
        stringsAsFactors = FALSE
      )
      print(comparison)
    }
  }
}

### Test 3: Check derived columns (OS_MONTHS, OS_STATUS)
test_derived_columns <- function(dataset_name, harmonized_file) {
  cat(sprintf("\n=== TEST 3: Derived Columns for %s ===\n", dataset_name))
  
  harmonized <- read_csv(harmonized_file, show_col_types = FALSE)
  df <- harmonized[harmonized$DATASET == dataset_name, ]
  
  # Test OS_STATUS derivation
  cat("\n--- OS_STATUS ---\n")
  status_table <- table(df$VITAL_STATUS, df$OS_STATUS, useNA = "ifany")
  print(status_table)
  
  # Check if mapping is correct
  alive_with_0 <- sum(df$VITAL_STATUS == "Alive" & df$OS_STATUS == "0", na.rm = TRUE)
  dead_with_1 <- sum(df$VITAL_STATUS == "Dead" & df$OS_STATUS == "1", na.rm = TRUE)
  total_mapped <- alive_with_0 + dead_with_1
  
  if (total_mapped == sum(!is.na(df$OS_STATUS))) {
    cat("  ✓ PASS: OS_STATUS correctly derived from VITAL_STATUS\n")
  } else {
    cat("  ⚠ WARNING: Some OS_STATUS values don't match VITAL_STATUS\n")
  }
  
  # Test OS_MONTHS calculation
  cat("\n--- OS_MONTHS ---\n")
  cat(sprintf("  Non-NA OS_MONTHS: %d / %d\n", sum(!is.na(df$OS_MONTHS)), nrow(df)))
  
  # Check a few cases manually
  sample_idx <- which(!is.na(df$OS_MONTHS))[1:min(5, sum(!is.na(df$OS_MONTHS)))]
  if (length(sample_idx) > 0) {
    cat("\n  Sample OS_MONTHS calculations:\n")
    sample_data <- df[sample_idx, c("VITAL_STATUS", "TIME_TO_DEATH_DAYS", 
                                    "TIME_TO_LAST_FOLLOWUP_DAYS", "OS_MONTHS")]
    print(sample_data)
  }
}

### Test 4: Check standardized values
test_standardized_values <- function(dataset_name, harmonized_file) {
  cat(sprintf("\n=== TEST 4: Standardized Values for %s ===\n", dataset_name))
  
  harmonized <- read_csv(harmonized_file, show_col_types = FALSE)
  df <- harmonized[harmonized$DATASET == dataset_name, ]
  
  # Check VITAL_STATUS
  cat("\n--- VITAL_STATUS ---\n")
  print(table(df$VITAL_STATUS, useNA = "ifany"))
  
  valid_values <- c("Alive", "Dead")
  invalid <- df$VITAL_STATUS[!is.na(df$VITAL_STATUS) & !(df$VITAL_STATUS %in% valid_values)]
  if (length(invalid) > 0) {
    cat(sprintf("  ⚠ Found %d invalid values: %s\n", 
                length(invalid), paste(unique(invalid), collapse = ", ")))
  } else {
    cat("  ✓ All values are standardized\n")
  }
  
  # Check GENDER
  cat("\n--- GENDER ---\n")
  print(table(df$GENDER, useNA = "ifany"))
  
  valid_values <- c("male", "female")
  invalid <- df$GENDER[!is.na(df$GENDER) & !(df$GENDER %in% valid_values)]
  if (length(invalid) > 0) {
    cat(sprintf("  ⚠ Found %d invalid values: %s\n", 
                length(invalid), paste(unique(invalid), collapse = ", ")))
  } else {
    cat("  ✓ All values are standardized\n")
  }
  
  # Check RECIST_RESPONSE
  cat("\n--- RECIST_RESPONSE ---\n")
  print(table(df$RECIST_RESPONSE, useNA = "ifany"))
  
  valid_values <- c("CR", "PR", "SD", "PD", "NE")
  invalid <- df$RECIST_RESPONSE[!is.na(df$RECIST_RESPONSE) & 
                                  !(df$RECIST_RESPONSE %in% valid_values)]
  if (length(invalid) > 0) {
    cat(sprintf("  ⚠ Found %d invalid values: %s\n", 
                length(invalid), paste(unique(invalid), collapse = ", ")))
  } else {
    cat("  ✓ All values are standardized\n")
  }
}

### Test 5: Missing data report
test_missing_data <- function(dataset_name, harmonized_file) {
  cat(sprintf("\n=== TEST 5: Missing Data Report for %s ===\n", dataset_name))
  
  harmonized <- read_csv(harmonized_file, show_col_types = FALSE)
  df <- harmonized[harmonized$DATASET == dataset_name, ]
  
  # Key columns to check
  key_cols <- c("PATIENT_ID", "SAMPLE_ID", "AGE_YEARS", "GENDER", 
                "VITAL_STATUS", "OS_MONTHS", "OS_STATUS",
                "RECIST_RESPONSE", "SAMPLE_TIMEPOINT")
  
  missing_report <- data.frame(
    Column = character(),
    Total_Rows = integer(),
    Missing = integer(),
    Pct_Missing = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (col in key_cols) {
    if (col %in% names(df)) {
      n_missing <- sum(is.na(df[[col]]))
      pct_missing <- round(100 * n_missing / nrow(df), 1)
      
      missing_report <- rbind(missing_report, data.frame(
        Column = col,
        Total_Rows = nrow(df),
        Missing = n_missing,
        Pct_Missing = pct_missing,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  print(missing_report)
  
  # Highlight concerning missing data
  high_missing <- missing_report[missing_report$Pct_Missing > 50, ]
  if (nrow(high_missing) > 0) {
    cat("\n  ⚠ WARNING: Columns with >50% missing data:\n")
    print(high_missing)
  }
}

# ============================================================
# RUN ALL TESTS
# ============================================================

run_all_tests <- function(dataset_name, dataset_files, mapping_file, harmonized_file) {
  
  cat(sprintf("\n╔════════════════════════════════════════════════════════╗\n"))
  cat(sprintf("║  TESTING HARMONIZATION FOR: %-26s ║\n", dataset_name))
  cat(sprintf("╚════════════════════════════════════════════════════════╝\n"))
  
  dataset_file <- dataset_files[[dataset_name]]
  
  # Run individual tests
  test_column_mapping(dataset_name, dataset_file, mapping_file, harmonized_file)
  test_derived_columns(dataset_name, harmonized_file)
  test_standardized_values(dataset_name, harmonized_file)
  test_missing_data(dataset_name, harmonized_file)
  
  cat("\n")
}

# ============================================================
# EXECUTE TESTS
# ============================================================

# Test all datasets row counts
test_row_counts(dataset_files, harmonized_file)

# Detailed test for specific dataset (e.g., Liu)
run_all_tests("Riaz", dataset_files, mapping_file, harmonized_file)

# Run for all datasets (optional)
# for (dataset_name in names(dataset_files)) {
#   run_all_tests(dataset_name, dataset_files, mapping_file, harmonized_file)
# }

cat("\n========== TESTING COMPLETE ==========\n")


