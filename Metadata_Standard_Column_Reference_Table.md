**Standard Column Reference Table**

**Complete Reference: Standard Column Names and Expected Values**

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **STANDARD\_COLUMN\_NAME**           **Data Type**   **Expected Values / Format**                 **Description**                                   **Example**
  ------------------------------------ --------------- -------------------------------------------- ------------------------------------------------- ------------------------
  **COORDINATE\_ID**                   Character       Unique sample identifier                     Unique ID for each RNA-seq sample                 TCGA-D3-A1Q5-01A

  **SAMPLE\_ID**                       Character       Any unique sample ID                         Sample identifier                                 Sample\_001

  **PATIENT\_ID**                      Character       Any unique patient ID                        Patient identifier                                Patient1, Pt001

  **FILE\_NAME**                       Character       Filename string                              Original filename or data source                  data\_file\_001.bam

  **DATASET**                          Character       Dataset name                                 Source dataset (auto-generated)                   TCGA\_SKCM, Riaz, Liu

                                                                                                                                                      

  **AGE\_YEARS**                       Numeric         0-120                                        Patient age in years                              65, 58.5

  **AGE\_CATEGORY**                    Character       \"0-18 years\"\                              Age group categories                              \"51-60 years\"
                                                       \"18-30 years\"\                                                                               
                                                       \"31-40 years\"\                                                                               
                                                       \"41-50 years\"\                                                                               
                                                       \"51-60 years\"\                                                                               
                                                       \"61-70 years\"\                                                                               
                                                       \"71-80 years\"\                                                                               
                                                       \"81-100 years\"                                                                               

                                                                                                                                                      

  **GENDER**                           Character       \"male\"\                                    Patient sex/gender                                male
                                                       \"female\"                                                                                     

  **RACE**                             Character       \"White\"\                                   Patient race                                      White
                                                       \"Black or African American\"\                                                                 
                                                       \"Asian\"\                                                                                     
                                                       Other descriptive values                                                                       

  **ETHNICITY**                        Character       \"Hispanic or Latino\"\                      Patient ethnicity                                 Not Hispanic or Latino
                                                       \"Not Hispanic or Latino\"                                                                     

                                                                                                                                                      

  **VITAL\_STATUS**                    Character       \"Alive\"\                                   Patient vital status                              Alive
                                                       \"Dead\"                                                                                       

  **TIME\_TO\_DEATH\_DAYS**            Numeric         Positive number                              Days from diagnosis/treatment to death            245.5

  **TIME\_TO\_LAST\_FOLLOWUP\_DAYS**   Numeric         Positive number                              Days from diagnosis/treatment to last follow-up   730.0

  **OS\_MONTHS**                       Numeric         Positive number                              Overall survival in months                        24.5

  **OS\_STATUS**                       Character       \"0\" (Alive)\                               Overall survival status (binary)                  1
                                                       \"1\" (Dead)                                                                                   

  **PFS**                              Numeric         Positive number                              Progression-free survival in months               12.3

                                                                                                                                                      

  **PROGRESSION**                      Character       \"Yes\"\                                     Disease progression status                        Yes
                                                       \"No\"                                                                                         

  **RECURRENCE**                       Character       \"Yes\"\                                     Disease recurrence status                         No
                                                       \"No\"                                                                                         

                                                                                                                                                      

  **WHO\_GRADE**                       Character       \"WHO 1\"\                                   WHO tumor grade                                   WHO 3
                                                       \"WHO 2\"\                                                                                     
                                                       \"WHO 3\"\                                                                                     
                                                       \"WHO 4\"                                                                                      

  **AJCC\_STAGE**                      Character       \"Stage 0\"\                                 AJCC cancer stage                                 Stage III
                                                       \"Stage I\"\                                                                                   
                                                       \"Stage II\"\                                                                                  
                                                       \"Stage III\"\                                                                                 
                                                       \"Stage IV\"                                                                                   

  **T\_STAGE**                         Character       \"T0\", \"T1\", \"T1a\", \"T1b\", \"T1c\"\   Primary tumor stage                               T2a
                                                       \"T2\", \"T2a\", \"T2b\", \"T2c\"\                                                             
                                                       \"T3\", \"T3a\", \"T3b\", \"T3c\"\                                                             
                                                       \"T4\", \"T4a\", \"T4b\", \"T4c\"                                                              

  **N\_STAGE**                         Character       \"N0\"\                                      Regional lymph node stage                         N1
                                                       \"N1\", \"N1a\", \"N1b\", \"N1c\"\                                                             
                                                       \"N2\", \"N2a\", \"N2b\", \"N2c\"\                                                             
                                                       \"N3\", \"N3a\", \"N3b\", \"N3c\"                                                              

  **M\_STAGE**                         Character       \"M0\"\                                      Distant metastasis stage                          M1A
                                                       \"M1\"\                                                                                        
                                                       \"M1A\"\                                                                                       
                                                       \"M1B\"\                                                                                       
                                                       \"M1C\"\                                                                                       
                                                       \"IIIC\"                                                                                       

                                                                                                                                                      

  **PRIMARY\_MET**                     Character       \"Primary\"\                                 Primary tumor vs metastatic                       Metastatic
                                                       \"Metastatic\"                                                                                 

  **DIAGNOSIS**                        Character       \"acral\"\                                   Melanoma subtype/diagnosis                        cutaneous
                                                       \"mucosal\"\                                                                                   
                                                       \"cutaneous\"\                                                                                 
                                                       \"nodular\"\                                                                                   
                                                       \"occult\"\                                                                                    
                                                       \"ocular/uveal\"\                                                                              
                                                       \"superficial spreading\"\                                                                     
                                                       \"other\"                                                                                      

                                                                                                                                                      

  **TREATMENT\_IMMUNOTHERAPY**         Character       \"Nivolumab\"\                               Immunotherapy treatment                           Pembrolizumab
                                                       \"Pembrolizumab\"\                                                                             
                                                       \"Ipilimumab\"\                                                                                
                                                       \"Ipilimumab+Nivolumab\"\                                                                      
                                                       \"Ipilimumab+Pembrolizumab\"\                                                                  
                                                       Other combinations                                                                             

  **TREATMENT\_CHEMOTHERAPY**          Character       Drug names or \"Yes\"/\"No\"                 Chemotherapy treatment                            Dacarbazine

  **TREATMENT\_TARGETED**              Character       Drug names or \"Yes\"/\"No\"                 Targeted therapy treatment                        Vemurafenib

  **TREATMENT\_RADIATION**             Character       \"Yes\"\                                     Radiation therapy                                 No
                                                       \"No\"\                                                                                        
                                                       Descriptive text                                                                               

  **PRIOR\_TREATMENT**                 Character       \"Yes\"\                                     Any prior cancer treatment                        Yes
                                                       \"No\"                                                                                         

  **PRIOR\_MALIGNANCY**                Character       \"Yes\"\                                     Prior cancer diagnosis                            No
                                                       \"No\"                                                                                         

                                                                                                                                                      

  **SAMPLE\_TIMEPOINT**                Character       \"Pre-treatment\"\                           When sample was collected                         Pre-treatment
                                                       \"On-treatment\"\                                                                              
                                                       \"Post-treatment\"                                                                             

  **SITE\_OF\_RESECTION**              Character       \"Lymph node\"\                              Anatomical site of biopsy                         Lymph node
                                                       \"Skin/Soft tissue\"\                                                                          
                                                       \"Brain\"\                                                                                     
                                                       \"Lung\"\                                                                                      
                                                       \"Liver\"\                                                                                     
                                                       \"Bone\"\                                                                                      
                                                       \"Abdomen/GI\"\                                                                                
                                                       \"Thorax\"\                                                                                    
                                                       \"Primary tumor\"\                                                                             
                                                       \"Other organ\"\                                                                               
                                                       \"Pelvis\"\                                                                                    
                                                       \"Mass/Nodule\"                                                                                

                                                                                                                                                      

  **RECIST\_RESPONSE**                 Character       \"CR\" (Complete Response)\                  RECIST tumor response                             CR
                                                       \"PR\" (Partial Response)\                                                                     
                                                       \"PRCR\" (PR+CR)\                                                                              
                                                       \"SD\" (Stable Disease)\                                                                       
                                                       \"PD\" (Progressive Disease)\                                                                  
                                                       \"NE\" (Not Evaluable)\                                                                        
                                                       \"MR\" (Minor Response)                                                                        

  **RESPONDER\_NONRESPONDER**          Character       \"Responder\"\                               Binary response classification                    
                                                       \"Non-responder\"                                                                              
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
