library(readr)
library(readxl)
library(dplyr)

# ============================================================
# FILE PATHS
# ============================================================

setwd("./Melanoma/Metadata/")

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

mapping_file        <- "SKCM_column_mapping_guide.xlsx"
file_intermediate_1 <- "SKCM_harmonized_intermediate_1_mapped_columns.csv"
file_intermediate_2 <- "SKCM_harmonized_intermediate_2_survival_age.csv"
file_intermediate_3 <- "SKCM_harmonized_intermediate_3_standard_values.csv"
file_final          <- "SKCM_harmonized_metadata_V3_021726.csv"

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

### Convert a single value between time units
convert_time_with_unit <- function(value, source_unit, target_unit) {
  if (is.na(value)) return(NA_real_)
  
  to_days   <- c(days = 1, weeks = 7, months = 30.44, years = 365)
  from_days <- c(days = 1, weeks = 1/7, months = 1/30.44, years = 1/365)
  
  source_unit <- tolower(trimws(as.character(source_unit)))
  target_unit <- tolower(trimws(as.character(target_unit)))
  
  # Match unit strings to keys (e.g. "weeks" matches key "weeks")
  source_key <- names(to_days)[sapply(names(to_days), function(k) grepl(k, source_unit))][1]
  target_key <- names(to_days)[sapply(names(to_days), function(k) grepl(k, target_unit))][1]
  
  if (is.na(source_key) || is.na(target_key)) return(as.numeric(value))
  if (source_key == target_key) return(as.numeric(value))
  
  round(as.numeric(value) * to_days[source_key] * from_days[target_key], 2)
}

### Vectorised days-to-months
days_to_months <- function(days) {
  ifelse(is.na(days), NA_real_, days / 30.44)
}

# ============================================================
# STEP 1: MAP COLUMNS + TIME-UNIT CONVERSION (UPDATED)
# Output: file_intermediate_1
# ============================================================

compile_and_map_columns <- function(dataset_files, mapping_excel, output_file) {
  
  mapping_guide <- read_excel(mapping_excel)
  standard_cols <- mapping_guide[["STANDARD_COLUMN_NAMES"]]
  # Columns we keep in output (drop the _UNIT helper rows)
  output_cols   <- standard_cols[!grepl("_UNIT$", standard_cols)]
  
  # Time-conversion specs: which value column, which unit row, and target unit
  time_specs <- list(
    list(col = "AGE_YEARS",                  unit_row = "AGE_UNIT",                  target = "years"),
    list(col = "TIME_TO_DEATH_DAYS",        unit_row = "TIME_TO_DEATH_UNIT",        target = "days"),
    list(col = "TIME_TO_LAST_FOLLOWUP_DAYS",unit_row = "TIME_TO_LAST_FOLLOWUP_UNIT",target = "days"),
    list(col = "OS_MONTHS",                 unit_row = "OS_MONTHS_UNIT",            target = "months"),
    list(col = "PFS",                       unit_row = "PFS_UNIT",                  target = "months")
  )
  
  id_cols      <- c("COORDINATE_ID", "SAMPLE_ID", "PATIENT_ID", "FILE_NAME")
  numeric_cols <- c("AGE_YEARS", "TIME_TO_DEATH_DAYS", "TIME_TO_LAST_FOLLOWUP_DAYS", "OS_MONTHS", "PFS")
  
  harmonized_list <- list()
  
  for (dataset_name in names(dataset_files)) {
    file_path <- dataset_files[[dataset_name]]
    cat(paste0("\n[", dataset_name, "]\n"))
    
    # --- Read raw data -------------------------------------------------
    if (!file.exists(file_path)) {
      warning(paste0("  File not found: ", file_path))
      next
    }
    df <- if (grepl("\\.csv$", file_path)) {
      read_csv(file_path, show_col_types = FALSE)
    } else {
      read_excel(file_path)
    }
    cat(paste0("  Loaded: ", nrow(df), " rows, ", ncol(df), " columns\n"))
    
    # --- Build old->standard name mapping for this dataset ------------
    guide_col <- mapping_guide[[dataset_name]]
    if (is.null(guide_col)) {
      warning(paste0("  No mapping column found for ", dataset_name))
      next
    }
    
    # Create mapping dataframe to handle one-to-many relationships
    valid_mappings <- data.frame(
      original_col = guide_col,
      standard_col = standard_cols,
      stringsAsFactors = FALSE
    )
    # Keep only entries where original name exists in the dataset
    valid_mappings <- valid_mappings[
      !is.na(valid_mappings$original_col) & 
        valid_mappings$original_col != "" &
        valid_mappings$original_col %in% names(df),
    ]
    
    # --- Rename unique mappings first ---
    unique_mappings <- valid_mappings[!duplicated(valid_mappings$original_col), ]
    col_map <- setNames(unique_mappings$standard_col, unique_mappings$original_col)
    
    df_mapped <- df %>% dplyr::rename_with(
      .fn = function(old) col_map[old],
      .cols = names(col_map)
    )
    
    cat(paste0("  Mapped ", length(col_map), " unique columns\n"))
    
    # --- Handle duplicate mappings (same source -> multiple targets) ---
    duplicate_originals <- valid_mappings$original_col[duplicated(valid_mappings$original_col)]
    duplicate_originals <- unique(duplicate_originals)
    
    if (length(duplicate_originals) > 0) {
      cat(paste0("  Handling ", length(duplicate_originals), " duplicate source column(s):\n"))
      
      for (orig_col in duplicate_originals) {
        # Get all standard columns this original maps to
        target_cols <- valid_mappings$standard_col[valid_mappings$original_col == orig_col]
        
        # The first target was already renamed, so find it
        first_target <- target_cols[1]
        
        # Copy to additional target columns
        for (i in 2:length(target_cols)) {
          target_col <- target_cols[i]
          df_mapped[[target_col]] <- df_mapped[[first_target]]
          cat(paste0("    ", orig_col, " -> ", first_target, " (already mapped) + ", target_col, " (duplicated)\n"))
        }
      }
    }
    
    # --- Time-unit conversions -----------------------------------------
    for (spec in time_specs) {
      if (!(spec$col %in% names(df_mapped))) next
      
      # Look up the source unit from the mapping guide for this dataset
      unit_row_idx <- which(standard_cols == spec$unit_row)
      if (length(unit_row_idx) == 0) next
      source_unit  <- as.character(guide_col[unit_row_idx])
      if (is.na(source_unit) || source_unit == "") next
      
      # Convert in place (vectorised via sapply)
      df_mapped[[spec$col]] <- as.numeric(sapply(
        df_mapped[[spec$col]],
        convert_time_with_unit,
        source_unit = source_unit,
        target_unit = spec$target
      ))
      cat(paste0("  Converted ", spec$col, ": ", source_unit, " -> ", spec$target, "\n"))
    }
    
    # --- Add DATASET tag and fill missing standard columns ------------
    df_mapped$DATASET <- dataset_name
    
    for (col in output_cols) {
      if (!col %in% names(df_mapped)) df_mapped[[col]] <- NA_character_
    }
    
    # --- Cast types ----------------------------------------------------
    for (col in id_cols)      if (col %in% names(df_mapped)) df_mapped[[col]] <- as.character(df_mapped[[col]])
    for (col in numeric_cols) if (col %in% names(df_mapped)) df_mapped[[col]] <- as.numeric(df_mapped[[col]])
    
    char_cols <- setdiff(output_cols, c(id_cols, numeric_cols))
    for (col in char_cols)    if (col %in% names(df_mapped)) df_mapped[[col]] <- as.character(df_mapped[[col]])
    
    # --- Select and order final columns --------------------------------
    final_cols <- c("DATASET", output_cols)
    df_mapped  <- df_mapped %>% dplyr::select(all_of(final_cols))
    
    harmonized_list[[dataset_name]] <- df_mapped
    cat(paste0("  Output: ", nrow(df_mapped), " rows, ", ncol(df_mapped), " columns\n"))
  }
  
  if (length(harmonized_list) == 0) stop("No datasets were successfully processed!")
  
  combined <- bind_rows(harmonized_list)
  write_csv(combined, output_file)
  
  cat(paste0("\n✓ Saved: ", output_file, "\n"))
  cat(paste0("  Total rows: ", nrow(combined), ", columns: ", ncol(combined), "\n"))
  cat("  Dataset counts:\n")
  print(table(combined$DATASET))
  
  return(combined)
}

# ============================================================
# STEP 2: ADD OS_MONTHS, OS_STATUS, AGE_CATEGORY
# Output: file_intermediate_2
# ============================================================

create_age_category <- function(df) {
  if (!("AGE_YEARS" %in% names(df))) return(df)
  
  df %>% mutate(
    AGE_CATEGORY = case_when(
      # If an original category string exists, harmonise it
      !is.na(AGE_CATEGORY) ~ case_when(
        grepl("0.*18|<\\s*18|pediatric|child",              AGE_CATEGORY, ignore.case = TRUE) ~ "0-18 years",
        grepl("18.*30|young adult",                         AGE_CATEGORY, ignore.case = TRUE) ~ "18-30 years",
        grepl("31.*40|30.*40",                              AGE_CATEGORY, ignore.case = TRUE) ~ "31-40 years",
        grepl("41.*50|40.*50",                              AGE_CATEGORY, ignore.case = TRUE) ~ "41-50 years",
        grepl("51.*60|50.*60",                              AGE_CATEGORY, ignore.case = TRUE) ~ "51-60 years",
        grepl("61.*70|60.*70",                              AGE_CATEGORY, ignore.case = TRUE) ~ "61-70 years",
        grepl("71.*80|70.*80",                              AGE_CATEGORY, ignore.case = TRUE) ~ "71-80 years",
        grepl("81.*100|80.*100|>\\s*80|elderly|senior",     AGE_CATEGORY, ignore.case = TRUE) ~ "81-100 years",
        TRUE ~ AGE_CATEGORY
      ),
      # Otherwise derive from numeric age
      is.na(AGE_CATEGORY) & !is.na(AGE_YEARS) ~ case_when(
        AGE_YEARS <  18                          ~ "0-18 years",
        AGE_YEARS >= 18 & AGE_YEARS < 31         ~ "18-30 years",
        AGE_YEARS >= 31 & AGE_YEARS < 41         ~ "31-40 years",
        AGE_YEARS >= 41 & AGE_YEARS < 51         ~ "41-50 years",
        AGE_YEARS >= 51 & AGE_YEARS < 61         ~ "51-60 years",
        AGE_YEARS >= 61 & AGE_YEARS < 71         ~ "61-70 years",
        AGE_YEARS >= 71 & AGE_YEARS < 81         ~ "71-80 years",
        AGE_YEARS >= 81 & AGE_YEARS <= 100       ~ "81-100 years",
        TRUE ~ NA_character_
      ),
      TRUE ~ NA_character_
    )
  )
}

add_survival_and_age_metrics <- function(input_file, output_file) {
  df <- read_csv(input_file, show_col_types = FALSE)
  
  df <- df %>%
    mutate(
      # FIRST: Standardize VITAL_STATUS before using it
      VITAL_STATUS = case_when(
        tolower(trimws(VITAL_STATUS)) %in% c("alive","living","0","a") ~ "Alive",
        tolower(trimws(VITAL_STATUS)) %in% c("dead","deceased","1","d") ~ "Dead",
        TRUE ~ VITAL_STATUS
      ),
      
      # THEN: Calculate OS from death/follow-up days when OS_MONTHS is missing
      OS_MONTHS = case_when(
        !is.na(OS_MONTHS)                                                        ~ OS_MONTHS,
        VITAL_STATUS == "Dead"  & !is.na(TIME_TO_DEATH_DAYS)                     ~ days_to_months(TIME_TO_DEATH_DAYS),
        VITAL_STATUS == "Alive" & !is.na(TIME_TO_LAST_FOLLOWUP_DAYS)            ~ days_to_months(TIME_TO_LAST_FOLLOWUP_DAYS),
        TRUE ~ NA_real_
      ),
      
      # NOW: Create OS_STATUS (will work correctly with standardized VITAL_STATUS)
      OS_STATUS = case_when(
        VITAL_STATUS == "Dead"  ~ "1",
        VITAL_STATUS == "Alive" ~ "0",
        TRUE ~ NA_character_
      )
    )
  
  df <- create_age_category(df)
  
  write_csv(df, output_file)
  cat(paste0("✓ Saved: ", output_file, "\n"))
  return(df)
}

# ============================================================
# STEP 3: HARMONIZE STANDARD COLUMN VALUES
# Output: file_intermediate_3
# ============================================================

harmonize_standard_values <- function(input_file, output_file) {
  df <- read_csv(input_file, show_col_types = FALSE)
  
  df_cleaned <- df %>% mutate(
    VITAL_STATUS = case_when(
      tolower(trimws(VITAL_STATUS)) %in% c("alive","living","0","a") ~ "Alive",
      tolower(trimws(VITAL_STATUS)) %in% c("dead","deceased","1","d") ~ "Dead",
      TRUE ~ VITAL_STATUS
    ),
    
    GENDER = case_when(
      tolower(trimws(GENDER)) %in% c("m","male")   ~ "male",
      tolower(trimws(GENDER)) %in% c("f","female") ~ "female",
      TRUE ~ GENDER
    ),
    
    WHO_GRADE = case_when(
      is.na(WHO_GRADE)                                          ~ NA_character_,
      grepl("^WHO", WHO_GRADE, ignore.case = TRUE)              ~ WHO_GRADE,
      grepl("^[1-4]$", trimws(WHO_GRADE))                       ~ paste0("WHO ", trimws(WHO_GRADE)),
      grepl("grade.*[1-4]", WHO_GRADE, ignore.case = TRUE)      ~ paste0("WHO ", gsub(".*([1-4]).*","\\1", WHO_GRADE)),
      TRUE ~ WHO_GRADE
    ),
    
    AJCC_STAGE = case_when(
      is.na(AJCC_STAGE) ~ NA_character_,
      grepl("^(0|stage\\s*0)$", AJCC_STAGE, ignore.case = TRUE) ~ "Stage 0",
      grepl("^(I|1|IA|IB|IC|stage\\s*I)", AJCC_STAGE, ignore.case = TRUE) &
        !grepl("II|III|IV|2|3|4", AJCC_STAGE, ignore.case = TRUE)            ~ "Stage I",
      grepl("^(II|2|IIA|IIB|IIC|stage\\s*II)", AJCC_STAGE, ignore.case = TRUE) &
        !grepl("III|IV|3|4", AJCC_STAGE, ignore.case = TRUE)                 ~ "Stage II",
      grepl("^(III|3|IIIA|IIIB|IIIC|IIID|stage\\s*III)", AJCC_STAGE, ignore.case = TRUE) &
        !grepl("IV|4", AJCC_STAGE, ignore.case = TRUE)                       ~ "Stage III",
      grepl("^(IV|4|IVA|IVB|IVC|stage\\s*IV)", AJCC_STAGE, ignore.case = TRUE) ~ "Stage IV",
      TRUE ~ AJCC_STAGE
    ),
    
    T_STAGE = case_when(
      tolower(trimws(T_STAGE)) %in% c("tx","unknown","not reported") ~ NA_character_,
      grepl("^T[0-4][a-c]?", T_STAGE, ignore.case = TRUE)           ~ toupper(T_STAGE),
      TRUE ~ T_STAGE
    ),
    N_STAGE = case_when(
      tolower(trimws(N_STAGE)) %in% c("nx","unknown","not reported") ~ NA_character_,
      grepl("^N[0-3][a-c]?", N_STAGE, ignore.case = TRUE)           ~ toupper(N_STAGE),
      TRUE ~ N_STAGE
    ),
    
    M_STAGE = case_when(
      is.na(M_STAGE)                                                          ~ NA_character_,
      tolower(trimws(M_STAGE)) %in% c("mx","unknown","not reported")          ~ NA_character_,
      trimws(M_STAGE) == "0"                                                  ~ "IIIC",
      trimws(M_STAGE) == "1"                                                  ~ "M1A",
      trimws(M_STAGE) == "2"                                                  ~ "M1B",
      trimws(M_STAGE) == "3"                                                  ~ "M1C",
      grepl("^M0",  M_STAGE, ignore.case = TRUE)                              ~ "M0",
      grepl("^M1A", M_STAGE, ignore.case = TRUE)                              ~ "M1A",
      grepl("^M1B", M_STAGE, ignore.case = TRUE)                              ~ "M1B",
      grepl("^M1C", M_STAGE, ignore.case = TRUE)                              ~ "M1C",
      grepl("^M1",  M_STAGE, ignore.case = TRUE) & !grepl("[ABC]", M_STAGE)   ~ "M1",
      grepl("^IIIC$", M_STAGE, ignore.case = TRUE)                            ~ "NE",
      TRUE ~ toupper(M_STAGE)
    ),
    
    PRIMARY_MET = case_when(
      tolower(trimws(PRIMARY_MET)) == "yes"                                              ~ "Metastatic",
      tolower(trimws(PRIMARY_MET)) == "no"                                               ~ "Primary",
      grepl("primary|tumor", PRIMARY_MET, ignore.case = TRUE) &
        !grepl("met", PRIMARY_MET, ignore.case = TRUE)                                   ~ "Primary",
      grepl("met|metasta", PRIMARY_MET, ignore.case = TRUE)                              ~ "Metastatic",
      TRUE ~ PRIMARY_MET
    ),
    
    RECIST_RESPONSE = case_when(
      is.na(RECIST_RESPONSE)                                                             ~ NA_character_,
      toupper(trimws(RECIST_RESPONSE)) %in% c("CR","COMPLETE RESPONSE")                  ~ "CR",
      toupper(trimws(RECIST_RESPONSE)) %in% c("PR","PARTIAL RESPONSE")                   ~ "PR",
      toupper(trimws(RECIST_RESPONSE)) %in% c("PRCR")                                    ~ "PRCR",
      toupper(trimws(RECIST_RESPONSE)) %in% c("SD","STABLE DISEASE","STABLE")            ~ "SD",
      toupper(trimws(RECIST_RESPONSE)) %in% c("PD","PROGRESSIVE DISEASE","PROGRESSION")  ~ "PD",
      toupper(trimws(RECIST_RESPONSE)) %in% c("NE","NOT EVALUABLE","UNK")                ~ "NE",
      toupper(trimws(RECIST_RESPONSE)) %in% c("MR","MINOR RESPONSE")                     ~ "MR",
      TRUE ~ RECIST_RESPONSE
    ),
    
    RESPONDER_NONRESPONDER = case_when(
      is.na(RESPONDER_NONRESPONDER) & !is.na(RECIST_RESPONSE) &
        toupper(trimws(RECIST_RESPONSE)) %in% c("CR","PR","PRCR")                        ~ "Responder",
      is.na(RESPONDER_NONRESPONDER) & !is.na(RECIST_RESPONSE) &
        toupper(trimws(RECIST_RESPONSE)) %in% c("SD","PD","NR","MR")                     ~ "Non-responder",
      toupper(trimws(RESPONDER_NONRESPONDER)) %in% c("R","RESPONDER","RESPONSE")         ~ "Responder",
      toupper(trimws(RESPONDER_NONRESPONDER)) %in% c("NR","NONRESPONDER","NON-RESPONDER")~ "Non-responder",
      grepl("responder|response|CR|PR|PRCR|^R$", RESPONDER_NONRESPONDER, ignore.case = TRUE) &
        !grepl("non|no", RESPONDER_NONRESPONDER, ignore.case = TRUE)                     ~ "Responder",
      grepl("non.?responder|no.?response|SD|PD|^NR$", RESPONDER_NONRESPONDER, ignore.case = TRUE) ~ "Non-responder",
      TRUE ~ RESPONDER_NONRESPONDER
    ),
    
    PROGRESSION = case_when(
      tolower(trimws(PROGRESSION)) %in% c("true","yes","1","y")  ~ "Yes",
      tolower(trimws(PROGRESSION)) %in% c("false","no","0","n")  ~ "No",
      TRUE ~ PROGRESSION
    ),
    RECURRENCE = case_when(
      tolower(trimws(RECURRENCE)) %in% c("true","yes","1","y")   ~ "Yes",
      tolower(trimws(RECURRENCE)) %in% c("false","no","0","n")   ~ "No",
      TRUE ~ RECURRENCE
    ),
    
    SAMPLE_TIMEPOINT = case_when(
      toupper(trimws(SAMPLE_TIMEPOINT)) == "PRE"                                         ~ "Pre-treatment",
      toupper(trimws(SAMPLE_TIMEPOINT)) == "EDT"                                         ~ "On-treatment",
      grepl("pre|baseline|before", SAMPLE_TIMEPOINT, ignore.case = TRUE)                 ~ "Pre-treatment",
      grepl("on|during|edt",       SAMPLE_TIMEPOINT, ignore.case = TRUE)                 ~ "On-treatment",
      grepl("post|after",          SAMPLE_TIMEPOINT, ignore.case = TRUE)                 ~ "Post-treatment",
      TRUE ~ SAMPLE_TIMEPOINT
    ),
    
    DIAGNOSIS = case_when(
      grepl("acral|lentiginous",                                          DIAGNOSIS, ignore.case = TRUE) ~ "acral",
      grepl("mucosal",                                                    DIAGNOSIS, ignore.case = TRUE) ~ "mucosal",
      grepl("ocular|uveal",                                               DIAGNOSIS, ignore.case = TRUE) ~ "ocular/uveal",
      grepl("cutaneous|skin",                                             DIAGNOSIS, ignore.case = TRUE) ~ "cutaneous",
      grepl("superficial spreading",                                      DIAGNOSIS, ignore.case = TRUE) ~ "superficial spreading",
      grepl("nodular",                                                    DIAGNOSIS, ignore.case = TRUE) ~ "nodular",
      grepl("occult",                                                     DIAGNOSIS, ignore.case = TRUE) ~ "occult",
      grepl("amelanotic|desmoplastic|epithelioid|lentigo|spindle|OTHER|^other$",        DIAGNOSIS, ignore.case = TRUE) ~ "other",
      grepl("melanoma.*nos|malignant melanoma",                            DIAGNOSIS, ignore.case = TRUE) ~ "malignant melanoma",
      TRUE ~ DIAGNOSIS
    ),
    
    ETHNICITY = case_when(
      tolower(trimws(ETHNICITY)) %in% c("not reported","unknown")                       ~ NA_character_,
      grepl("not hispanic|not latino", ETHNICITY, ignore.case = TRUE)                    ~ "Not Hispanic or Latino",
      grepl("hispanic|latino",     ETHNICITY, ignore.case = TRUE)                        ~ "Hispanic or Latino",
      TRUE ~ ETHNICITY
    ),
    RACE = case_when(
      tolower(trimws(RACE)) %in% c("not reported","unknown")                            ~ NA_character_,
      grepl("white|caucasian",  RACE, ignore.case = TRUE)                               ~ "White",
      grepl("black|african",    RACE, ignore.case = TRUE)                               ~ "Black or African American",
      grepl("asian",            RACE, ignore.case = TRUE)                               ~ "Asian",
      TRUE ~ RACE
    ),
    
    PRIOR_TREATMENT = case_when(
      tolower(trimws(PRIOR_TREATMENT)) %in% c("yes","true","1")                         ~ "Yes",
      tolower(trimws(PRIOR_TREATMENT)) %in% c("no","false","0","none","naive")           ~ "No",
      TRUE ~ PRIOR_TREATMENT
    ),
    PRIOR_MALIGNANCY = case_when(
      tolower(trimws(PRIOR_MALIGNANCY)) %in% c("yes","true","1")                        ~ "Yes",
      tolower(trimws(PRIOR_MALIGNANCY)) %in% c("no","false","0")                        ~ "No",
      TRUE ~ PRIOR_MALIGNANCY
    ),
    
    across(where(is.character), trimws)
  )
  
  write_csv(df_cleaned, output_file)
  cat(paste0("✓ Saved: ", output_file, "\n"))
  return(df_cleaned)
}

# ============================================================
# STEP 4: HARMONIZE CUSTOM COLUMNS
# Output: file_final
# ============================================================

harmonize_custom_columns <- function(input_file, output_file) {
  df <- read_csv(input_file, show_col_types = FALSE)
  
  df_final <- df %>% mutate(
    TREATMENT_IMMUNOTHERAPY = case_when(
      is.na(TREATMENT_IMMUNOTHERAPY) ~ NA_character_,
      grepl("ipi.*nivo|nivo.*ipi", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE)                                          ~ "Ipilimumab+Nivolumab",
      grepl("ipilimumab.*pembrolizumab|pembrolizumab.*ipilimumab", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE)           ~ "Ipilimumab+Pembrolizumab",
      grepl("^nivo$|nivolumab|NIV3", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE) &
        !grepl("ipi|pembrolizumab", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE)                                          ~ "Nivolumab",
      grepl("^pembro$|pembrolizumab", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE) &
        !grepl("ipi|nivo", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE)                                                   ~ "Pembrolizumab",
      grepl("^ipi$|^ipilimumab$", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE) &
        !grepl("nivo|pembro", TREATMENT_IMMUNOTHERAPY, ignore.case = TRUE)                                                ~ "Ipilimumab",
      TRUE ~ TREATMENT_IMMUNOTHERAPY
    ),
    
    SITE_OF_RESECTION = case_when(
      is.na(SITE_OF_RESECTION)                                                   ~ NA_character_,
      # Lymph node
      grepl("lymph|LN", SITE_OF_RESECTION, ignore.case = TRUE)                   ~ "Lymph node",
      # Skin/Soft tissue (including specific anatomical sites)
      grepl("^skin$|cutaneous|subcutaneous|^SQ$|skin.*NOS", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Skin/Soft tissue",
      grepl("skin.*lower.*limb|skin.*hip", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Skin/Soft tissue",
      grepl("skin.*upper.*limb|skin.*shoulder", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Skin/Soft tissue",
      grepl("skin.*face|skin.*ear", SITE_OF_RESECTION, ignore.case = TRUE)       ~ "Skin/Soft tissue",
      grepl("skin.*trunk", SITE_OF_RESECTION, ignore.case = TRUE)                ~ "Skin/Soft tissue",
      grepl("external ear", SITE_OF_RESECTION, ignore.case = TRUE)               ~ "Skin/Soft tissue",
      grepl("soft.*tissue|connective.*soft", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Skin/Soft tissue",
      # Brain
      grepl("brain|frontal lobe|parietal lobe", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Brain",
      # Lung
      grepl("lung", SITE_OF_RESECTION, ignore.case = TRUE)                       ~ "Lung",
      # Liver
      grepl("liver", SITE_OF_RESECTION, ignore.case = TRUE)                      ~ "Liver",
      # Bone
      grepl("bone|skull|spine", SITE_OF_RESECTION, ignore.case = TRUE)           ~ "Bone",
      # Abdomen/GI
      grepl("abdomen|colon|jejunum|small intestine|rectum|peritoneum|stomach|AMENTIM", 
            SITE_OF_RESECTION, ignore.case = TRUE)                               ~ "Abdomen/GI",
      # Thorax
      grepl("thorax|chest|SUBCLAVICULAR", SITE_OF_RESECTION, ignore.case = TRUE) ~ "Thorax",
      # Primary tumor
      grepl("^primary$|primary tumor", SITE_OF_RESECTION, ignore.case = TRUE)    ~ "Primary tumor",
      # Other organ
      grepl("adrenal|spleen|thyroid|spinal|parotid|vagina|vulva|endometrium|mucosa|nasal",
            SITE_OF_RESECTION, ignore.case = TRUE)                               ~ "Other organ",
      # Pelvis
      grepl("pelvis|pelvic", SITE_OF_RESECTION, ignore.case = TRUE)              ~ "Pelvis",
      # Mass/Nodule
      grepl("MASS|NODULE|NECK", SITE_OF_RESECTION, ignore.case = TRUE)           ~ "Mass/Nodule",
      TRUE ~ SITE_OF_RESECTION
    ),
    
    # Fill SAMPLE_TIMEPOINT for datasets known to be all pre-treatment
    SAMPLE_TIMEPOINT = case_when(
      is.na(SAMPLE_TIMEPOINT) & toupper(trimws(DATASET)) %in% c("LIU","HELMINK") ~ "Pre-treatment",
      TRUE ~ SAMPLE_TIMEPOINT
    )
  )
  
  write_csv(df_final, output_file)
  cat(paste0("✓ Saved: ", output_file, "\n"))
  return(df_final)
}

# ============================================================
# MAIN EXECUTION PIPELINE
# ============================================================

cat("========== STEP 1: Column mapping + time conversion ==========\n")
step1_data <- compile_and_map_columns(
  dataset_files = dataset_files,
  mapping_excel = mapping_file,
  output_file   = file_intermediate_1
)

cat("\n========== STEP 2: Survival & age metrics ==========\n")
step2_data <- add_survival_and_age_metrics(
  input_file  = file_intermediate_1,
  output_file = file_intermediate_2
)

cat("\n========== STEP 3: Standardise values ==========\n")
step3_data <- harmonize_standard_values(
  input_file  = file_intermediate_2,
  output_file = file_intermediate_3
)

cat("\n========== STEP 4: Custom column harmonization ==========\n")
final_data <- harmonize_custom_columns(
  input_file  = file_intermediate_3,
  output_file = file_final
)

cat("\n========== PIPELINE COMPLETE ==========\n")



