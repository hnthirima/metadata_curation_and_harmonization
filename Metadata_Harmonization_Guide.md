# **Metadata Harmonization Guide**

## **Overview**

This guide walks you through harmonizing metadata from multiple datasets
into a single standardized format.

The process involves three main steps:

1. compiling individual dataset metadata
2. creating a column mapping guide
3. running an automated R script to generate the final harmonized
    metadata file.

NOTE: This version may not capture all available clinical variables.
Modify the scripts and mapping files to accommodate additional data
fields as needed.

## **Prerequisites**

#### **Required Software**

-   R (version 4.0 or higher)
-   RStudio (recommended)

#### **Required R Packages**

install.packages(c(\"readr\", \"readxl\", \"dplyr\"))

#### **Required Files**

1. Individual dataset metadata files (CSV or Excel format)
2. Column mapping guide template (Excel file)
3. Harmonization R script

## **Step 1: Compile Metadata for Each Dataset**

### **1.1 Prepare Individual Dataset Files**

For each dataset (e.g., TCGA\_SKCM, Riaz, Liu, Hugo, etc.), create a
**CSV or Excel file** containing all available metadata.

**File naming convention:**

\<Dataset\_Name\>.csv

**Examples:**

-   TCGA\_SKCM.csv
-   Riaz.csv
-   Liu.csv

### **1.2 Essential Metadata Columns**

Each dataset file should contain as many of the following columns as
available:

**Patient and Sample Identifiers:**

-   Sample ID
-   Patient ID
-   Coordinate ID (unique identifier for RNA-seq samples that map to
    landscape coordinate IDs)

**Demographics:**

-   Age
-   Gender/Sex
-   Race
-   Ethnicity

**Clinical Information:**

-   Vital status (Alive/Dead)
-   Overall survival time
-   Progression-free survival time
-   Time to death
-   Time to last follow-up
-   AJCC stage
-   T stage, N stage, M stage
-   Primary vs Metastatic
-   Diagnosis (pathological classification)

**Treatment Information:**

-   Treatment type (immunotherapy)
-   Prior treatment history
-   Sample timepoint (Pre-treatment, On-treatment, Post-treatment)
-   Response (RECIST, Responder/Non-responder)
-   Progression status
-   Recurrence status

**Sample Information:**

-   Site of resection/biopsy
-   Sample type

### **1.3 Important Notes**

-   **Keep original column names** - You will map them to standardized
    names in Step 2
-   **Include all available data** - Even if columns don\'t match across
    datasets
-   **Use consistent values within each dataset** - But don\'t worry
    about consistency across datasets yet
-   **Save files in CSV format** (preferred) or Excel format

**Example dataset file structure:**

      patient\_id           age     sex       vital\_status       os\_months      treatment       response
      ----------------- --------- --------- ------------------- ---------------- --------------- --------------
      PT001                65          M           Alive                 24.5       Nivolumab         CR
      PT002                58          F           Dead                  8.2        Pembrolizumab     PD

### **1.4 Organize Files**

Place all dataset CSV/Excel files in a single directory:

    /project\_directory/
    ├── TCGA\_SKCM.csv
    ├── Riaz.csv
    ├── Liu.csv

## **Step 2: Create Column Mapping Guide**

### **2.1 Download Mapping Template**

Create an Excel file named \[TumorType\]\_column\_mapping\_guide.xlsx
with the following structure:

### **2.2 Template Structure**

**Column A: STANDARD\_COLUMN\_NAMES** (Fixed - Do Not Change)

This column contains the standardized column names that all datasets
will be mapped to:

- STANDARD\_COLUMN\_NAMES
- COORDINATE\_ID
- SAMPLE\_ID
- PATIENT\_ID
- FILE\_NAME
- AGE\_YEARS
- AGE\_UNIT
- AGE\_CATEGORY
- GENDER
- RACE
- ETHNICITY
- VITAL\_STATUS
- TIME\_TO\_DEATH\_DAYS
- TIME\_TO\_DEATH\_UNIT
- TIME\_TO\_LAST\_FOLLOWUP\_DAYS
- TIME\_TO\_LAST\_FOLLOWUP\_UNIT
- OS\_MONTHS
- OS\_MONTHS\_UNIT
- OS\_STATUS
- PFS
- PFS\_UNIT
- PROGRESSION
- RECURRENCE
- WHO\_GRADE
- AJCC\_STAGE
- T\_STAGE
- N\_STAGE
- M\_STAGE
- PRIMARY\_MET
- DIAGNOSIS
- TREATMENT\_IMMUNOTHERAPY
- TREATMENT\_CHEMOTHERAPY
- TREATMENT\_TARGETED
- TREATMENT\_RADIATION
- PRIOR\_TREATMENT
- PRIOR\_MALIGNANCY
- SAMPLE\_TIMEPOINT
- SITE\_OF\_RESECTION
- RECIST\_RESPONSE
- RESPONDER\_NONRESPONDER

**Columns B onwards: One column per dataset**

Each additional column represents one dataset. Column header = dataset
name (matching the CSV filename without extension).

**Example:**

    STANDARD\_COLUMN\_NAMES              TCGA\_SKCM             Riaz        Liu
      ----------------------------- ----------------------- ------------ ------------
      COORDINATE\_ID                bcr\_patient\_barcode   Sample\_ID   Sample
      PATIENT\_ID                   bcr\_patient\_barcode   Patient      Patient
      AGE\_YEARS                    age\_at\_diagnosis      Age          age
      AGE\_UNIT                     years                   years        years
      GENDER                        gender                  Sex          gender
      VITAL\_STATUS                 vital\_status           Status       os\_status
      OS\_MONTHS                    OS.time                 OS           os\_months
      OS\_MONTHS\_UNIT              months                  months       months

### **2.3 How to Fill the Mapping Guide**

For each dataset column (B, C, D, etc.):
1.  **Find the corresponding column** in your dataset CSV file
2.  **Enter the EXACT column name** from the dataset file
    (case-sensitive)
3.  **Leave blank** if the dataset doesn\'t have that information

**Special rows - UNIT specifications:**

For time-related columns, specify the unit in the corresponding \_UNIT
row:

-   AGE\_UNIT: years, months, days
-   TIME\_TO\_DEATH\_UNIT: days, weeks, months, years
-   TIME\_TO\_LAST\_FOLLOWUP\_UNIT: days, weeks, months, years
-   OS\_MONTHS\_UNIT: months, weeks, days
-   PFS\_UNIT: months, weeks, days

**Example mapping for Liu dataset:**

      STANDARD\_COLUMN\_NAMES           Liu
      ----------------------------- -------------
      COORDINATE\_ID                Sample
      PATIENT\_ID                   Patient
      AGE\_YEARS                    age
      AGE\_UNIT                     years
      TIME\_TO\_DEATH\_DAYS         death\_time
      TIME\_TO\_DEATH\_UNIT         days
      OS\_MONTHS                    
      OS\_MONTHS\_UNIT              

### **2.4 One-to-Many Mapping (Advanced)**

The script supports mapping **one source column to multiple standard
columns**.

**Example:** If Riaz has a single \"survival\_time\" column that should
populate both OS\_MONTHS and PFS:

        STANDARD\_COLUMN\_NAMES          Riaz
      ----------------------------- ----------------
      OS\_MONTHS                    survival\_time
      OS\_MONTHS\_UNIT              months
      PFS                           survival\_time
      PFS\_UNIT                     months

The script will automatically duplicate the data.

### **2.5 Save the Mapping Guide**

-   Save as: \[TumorType\]\_column\_mapping\_guide.xlsx
-   Place in the same directory as your dataset files

## **Step 3: Run Harmonization Script**

### **3.1 Open the R Script**

Open metadata\_harmonization\_template.R in RStudio.

### **3.2 Verify File Paths**

At the top of the script, check that the file paths are correct:
    dataset_files <- list(
    TCGA_SKCM = "TCGA_SKCM.csv",
    Riaz = "Riaz.csv",
    Ribas = "Ribas.csv",
    Liu = "Liu.csv"
    )

    mapping_file <- "SKCM_column_mapping_guide.xlsx"
    file_intermediate_1 <- "SKCM_harmonized_intermediate_1_mapped_columns.csv"
    file_intermediate_2 <- "SKCM_harmonized_intermediate_2_survival_age.csv"
    file_intermediate_3 <-  "SKCM_harmonized_intermediate_3_standard_values.csv"
    file_final <- "SKCM_harmonized_metadata_V2_020526.csv"

**Modify if needed:**

-   Add/remove datasets from the dataset\_files list
-   Change file names to match your files
-   Update output file names if desired

### **3.3 Set Working Directory**

In RStudio, set your working directory to where your files are located:
    setwd("/path/to/your/project_directory")
    Or use: Session > Set Working Directory > Choose Directory

### **3.4 Run the Script**

Run the entire script:

### **3.5 Monitor Progress**

The script will print progress messages:

========== STEP 1: Column mapping + time conversion ==========

    [TCGA_SKCM]
    Loaded: 470 rows, 35 columns
    Mapped 28 unique columns
    Converted OS\_MONTHS: months -\> months
    Output: 470 rows, 45 columns

    [Riaz]
    Loaded: 51 rows, 22 columns
    Mapped 18 unique columns
    Handling 1 duplicate source column(s):
    survival_time -> OS_MONTHS (already mapped) + PFS (duplicated)
    Output: 51 rows, 45 columns

✓ Saved: SKCM\_harmonized\_intermediate\_1\_mapped\_columns.csv

Total rows: 1151, columns: 46

Dataset counts:
TCGA\_SKCM Hugo Liu Riaz
470          28  42   51

========== STEP 2: Survival & age metrics ==========

✓ Saved: SKCM\_harmonized\_intermediate\_2\_survival\_age.csv

========== STEP 3: Standardise values ==========

✓ Saved: SKCM\_harmonized\_intermediate\_3\_standard\_values.csv

========== STEP 4: Custom column harmonization ==========

✓ Saved: SKCM\_harmonized\_metadata\_V2\_020526.csv

========== PIPELINE COMPLETE ==========

## **Output Files**

The script generates 4 output files:

**1. SKCM\_harmonized\_intermediate\_1\_mapped\_columns.csv**

-   **Purpose:** Column names mapped to standard names, time units
    converted
-   **Use:** Check if column mapping worked correctly
-   **Key features:**
    -   All datasets combined
    -   Column names standardized
    -   Time values converted to standard units (years for age, days for
        death/followup, months for OS/PFS)

**2. SKCM\_harmonized\_intermediate\_2\_survival\_age.csv**

-   **Purpose:** Derived survival metrics and age categories added
-   **New columns:**
    -   OS\_STATUS: Derived from VITAL\_STATUS (0=Alive, 1=Dead)
    -   OS\_MONTHS: Calculated from TIME\_TO\_DEATH\_DAYS or
        TIME\_TO\_LAST\_FOLLOWUP\_DAYS if missing
    -   AGE\_CATEGORY: Age groups (0-18, 18-30, 31-40, etc.)

**3. SKCM\_harmonized\_intermediate\_3\_standard\_values.csv**
-   **Purpose:** Categorical values standardized across datasets
-   **Standardizations applied:**
    -   VITAL\_STATUS: \"Alive\" or \"Dead\"
    -   GENDER: \"male\" or \"female\"
    -   AJCC\_STAGE: \"Stage I\", \"Stage II\", \"Stage III\", \"Stage
        IV\"
    -   M\_STAGE: \"M0\", \"M1A\", \"M1B\", \"M1C\", \"IIIC\"
    -   RECIST\_RESPONSE: \"CR\", \"PR\", \"PRCR\", \"SD\", \"PD\",
        \"NE\", \"MR\"
    -   RESPONDER\_NONRESPONDER: \"Responder\" or \"Non-responder\"
    -   SAMPLE\_TIMEPOINT: \"Pre-treatment\", \"On-treatment\",
        \"Post-treatment\"
    -   DIAGNOSIS: \"acral\", \"mucosal\", \"cutaneous\", \"nodular\",
        \"occult\", \"ocular/uveal\", \"superficial spreading\",
        \"other\"
    -   ETHNICITY: \"Hispanic or Latino\", \"Not Hispanic or Latino\"
    -   RACE: \"White\", \"Black or African American\", \"Asian\"

**4. SKCM\_harmonized\_metadata\_V2\_020526.csv ⭐ FINAL OUTPUT**

-   **Purpose:** Fully harmonized metadata ready for analysis
-   **Custom harmonizations:**
    -   TREATMENT\_IMMUNOTHERAPY: \"Nivolumab\", \"Pembrolizumab\",
        \"Ipilimumab\", \"Ipilimumab+Nivolumab\", etc.
    -   SITE\_OF\_RESECTION: Grouped into major categories (Lymph node,
        Skin/Soft tissue, Brain, Lung, Liver, etc.)
    -   Dataset-specific SAMPLE\_TIMEPOINT filled (Liumarked as
        \"Pre-treatment\")

# **Validation and Testing**

## **Use the Testing Script**

Run metadata\_harmonization\_testing.R to validate your harmonized metadata:
    source("metadata_harmonization_testing.R") 

    # Test all datasets
    test_row_counts(dataset_files, harmonized_file)

    # Detailed test for specific dataset
    run_all_tests("Liu", dataset_files, mapping_file, harmonized_file)



## **What to Check**

**1. Row Count Preservation**

test\_row\_counts(dataset\_files,
\"SKCM\_harmonized\_metadata\_V2\_020526.csv\")

-   Verifies no samples were lost or duplicated
-   Each dataset should have the same number of rows before and after

**2. Column Mapping Accuracy**

test\_column\_mapping(\"Liu\", \"Liu.csv\", mapping\_file,
harmonized\_file,

columns\_to\_check = c(\"TIME\_TO\_DEATH\_DAYS\", \"OS\_MONTHS\"))

-   Checks if columns were correctly mapped
-   Compares original vs harmonized values
-   Verifies unit conversions

**3. Derived Columns**

test\_derived\_columns(\"Liu\", harmonized\_file)

-   Validates OS\_STATUS derived from VITAL\_STATUS
-   Checks OS\_MONTHS calculations

**4. Standardized Values**

test\_standardized\_values(\"Liu\", harmonized\_file)

-   Ensures categorical values are standardized
-   Flags any non-standard values

**5. Missing Data Analysis**

test\_missing\_data(\"Liu\", harmonized\_file)

-   Reports missing data percentages
-   Identifies columns with \>50% missing data

## **Manual Spot Checks**

Open the final CSV in Excel/R and verify:

**Check 1: Sample counts**

    final_data <- read.csv("SKCM_harmonized_metadata_V2_020526.csv")
    table(final_data$DATASET)


**Check 2: Standardized values**

    table(final_data$VITAL_STATUS)  # Should only be "Alive" or "Dead"
    table(final_data$GENDER)        # Should only be "male" or "female"
    table(final_data$RECIST_RESPONSE)


**Check 3: Specific patients**

    Check a known patient from original dataset
    liu_data <- read.csv("Liu.csv")
    liu_patient <- liu_data[liu_data$Patient == "Patient1", ]

    harmonized_patient <- final_data[final_data$PATIENT_ID == "Patient1" & 
                                      final_data$DATASET == "Liu", ]

    Compare key values
    liu_patient$age  # vs harmonized_patient$AGE_YEARS


## **Troubleshooting**

## **Common Issues**

**Issue 1: \"File not found\" error**

Error: File not found: TCGA\_SKCM.csv

**Solution:**

-   Check your working directory: getwd()
-   Verify file names match exactly (case-sensitive)
-   Use setwd() to set correct directory
-   Or provide full file paths in the script

**Issue 2: \"No mapping column found for \[dataset\]\"**

Warning: No mapping column found for Riaz

**Solution:**

-   Check Excel column header exactly matches dataset name
-   Column name should be: \"Riaz\" (not \"Riaz.csv\" or \"riaz\")
-   Verify no extra spaces in column header

**Issue 3: Column names don\'t match**

Warning: Original column \'patient\_id\' not found in dataset

**Solution:**

-   Open your dataset CSV and check exact column name
-   Column names are case-sensitive: \"Patient\_ID\" ≠ \"patient\_id\"
-   Copy-paste column names from CSV into mapping guide to avoid typos

**Issue 4: Wrong number of rows after harmonization**

**Solution:**

-   Check for duplicate rows in original dataset
-   Run: test\_row\_counts(dataset\_files, harmonized\_file)
-   Verify COORDINATE\_ID, SAMPLE\_ID, PATIENT\_ID are correct

**Issue 5: OS\_STATUS is NA for some patients**

**Cause:** VITAL\_STATUS wasn\'t standardized before OS\_STATUS was
created

**Solution:**

-   Already fixed in current script (VITAL\_STATUS standardized in
    Step 2)
-   If issue persists, check for unusual VITAL\_STATUS values:

table(original\_data\$vital\_status\_column)

**Issue 6: Time values seem wrong**

**Cause:** Unit conversion error

**Solution:**

-   Check your \_UNIT rows in mapping guide
-   Verify source unit matches what\'s in the data
-   Common mistake: Dataset has days but you specified months

**Example fix in mapping guide:**

          STANDARD_COLUMN_NAMES         Liu 
          ----------------------------- ------------------------
          TIME_TO_DEATH_DAYS         death\_time
          TIME_TO_DEATH_UNIT         days ← Check this!


**Best Practices**

**1. Version Control**

-   Date your output files: SKCM\_harmonized\_metadata\_YYMMDD.csv
-   Keep intermediate files for debugging
-   Document any manual changes in a separate log file

**2. Backup Originals**

-   Never modify original dataset files
-   Keep a backup of your mapping guide
-   Save R script versions

**3. Iterative Refinement**

-   Run script on small subset first (2-3 datasets)
-   Check outputs thoroughly
-   Add remaining datasets once confident

**4. Documentation**

-   Add comments to mapping guide Excel file explaining unusual mappings
-   Note any dataset-specific quirks
-   Document any post-processing steps

**5. Quality Control Checklist**

-   \[ \] All dataset row counts preserved
-   \[ \] No duplicate samples (check COORDINATE\_ID)
-   \[ \] VITAL\_STATUS only contains \"Alive\" or \"Dead\"
-   \[ \] OS\_STATUS matches VITAL\_STATUS (Alive=0, Dead=1)
-   \[ \] Age values reasonable (0-100 years)
-   \[ \] Time values reasonable (no negative values)
-   \[ \] All DATASET labels correct
-   \[ \] Key clinical variables populated for most samples

**Example Workflow**

**Complete Example: Adding a New Dataset**

**Scenario:** You want to add a new dataset called \"VanAllen.csv\"

**Step 1:** Prepare the dataset file

VanAllen.csv with columns:

\- sample\_id
\- patient\_number
\- age\_at\_diagnosis
\- sex
\- OS\_days
\- response\_RECIST

**Step 2:** Add to mapping guide

Open SKCM\_column\_mapping\_guide.xlsx and add new column:

      STANDARD_COLUMN_NAMES            ...         VanAllen
      ----------------------------- ---------- --------------------
      COORDINATE_ID                    ...       sample_id
      PATIENT_ID                       ...       patient_number
      AGE_YEARS                        ...       age_at_diagnosis
      AGE_UNIT                         ...       years
      GENDER                           ...       sex
      OS_MONTHS                        ...       OS_days
      OS_MONTHS\_UNIT                  ...       days
      RECIST_RESPONSE                  ...       response_RECIST

**Step 3:** Update R script

Add to dataset\_files list:
dataset\_files \<- list(
TCGA\_SKCM = \"TCGA\_SKCM.csv\",
Riaz = \"Riaz.csv\",
\# \... other datasets \...
VanAllen = \"VanAllen.csv\" \# Add this line
)

**Step 4:** Run script

source(\"harmonize\_metadata\_updated.R\")

**Step 5:** Validate

source(\"test\_harmonization.R\")

run\_all\_tests(\"VanAllen\", dataset\_files, mapping\_file,
file\_final)

**Key Standardized Values**

**See "Metadata Standard Column Reference Table" document for more
information.**

      Column                       Allowed Values
      ------------------------- -------------------------------------------------
      VITAL_STATUS                 Alive, Dead
      GENDER                        male, female
      OS_STATUS                    0 (Alive), 1 (Dead)
      AJCC_STAGE                   Stage 0, Stage I, Stage II, Stage III, Stage IV
      M_STAGE                      M0, M1A, M1B, M1C, IIIC
      RECIST_RESPONSE              CR, PR, PRCR, SD, PD, NE, MR
      RESPONDER_NONRESPONDER       Responder, Non-responder
      SAMPLE_TIMEPOINT             Pre-treatment, On-treatment, Post-treatment
      PROGRESSION                   Yes, No
      RECURRENCE                    Yes, No
      PRIOR_TREATMENT               Yes, No
