######
# Generate Oncoscape-ready files
######

#merge with map coordinates
#generate separate sample-metadata and patient-metadata files
umap_coord <- read.csv("./melanoma_1369_bc_vst_umap2D.csv")
compiled_metadata <- read.csv("./SKCM_harmonized_metadata_V3_021726.csv")

sample_col <- c("COORDINATE_ID", 
                "SAMPLE_ID", 
                "PATIENT_ID", 
                "SAMPLE_TIMEPOINT",
                "PRIMARY_MET",
                "WHO_GRADE",
                "AJCC_STAGE",
                "T_STAGE",
                "N_STAGE",
                "M_STAGE",
                "SITE_OF_RESECTION",
                "RECURRENCE",
                "PROGRESSION", 
                "TIME_TO_PRETx_BIOPSY",
                "TIME_TO_PRETx_BIOPSY_UNIT")

nonpatient_col <- c("SAMPLE_TIMEPOINT",
                    "PRIMARY_MET",
                    "WHO_GRADE",
                    "AJCC_STAGE",
                    "T_STAGE",
                    "N_STAGE",
                    "M_STAGE",
                    "SITE_OF_RESECTION",
                    "RECURRENCE",
                    "PROGRESSION",
                    "TIME_TO_PRETx_BIOPSY",
                    "TIME_TO_PRETx_BIOPSY_UNIT")

#metadata file with sample-specific attributes
melanoma_sample <- compiled_metadata[, colnames(compiled_metadata) %in% sample_col]
mel_sample_umap <- left_join(umap_coord, melanoma_sample, by = "COORDINATE_ID")
write.csv(mel_sample_umap, "./02172026/melanoma_metadata_sample.csv")

#metadata file with patient-specific attributes
melanoma_patient <- compiled_metadata[, !(colnames(compiled_metadata) %in% nonpatient_col)]
mel_patient_umap <- left_join(umap_coord, melanoma_patient, by = "COORDINATE_ID")
write.csv(mel_patient_umap, "./02172026/melanoma_metadata_patient.csv")

#metadata file with all attributes in one file
mel_clinical_umap <- left_join(umap_coord, compiled_metadata, by = "COORDINATE_ID")
write.csv(mel_clinical_umap, "./02172026/melanoma_metadata_clinical.csv")




