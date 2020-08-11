Introduction
============

This is a demo of how to login and query Gen3 from R.

This is based on:

-   <a href="https://gen3.org/resources/user/using-api/" class="uri">https://gen3.org/resources/user/using-api/</a>
-   <a href="https://gen3.org/resources/developer/flat-model-api/" class="uri">https://gen3.org/resources/developer/flat-model-api/</a>
-   <a href="https://graphql.org/learn/queries/" class="uri">https://graphql.org/learn/queries/</a>
-   <a href="https://graphql.org/learn/introspection/" class="uri">https://graphql.org/learn/introspection/</a>

A very useful facility for formulating GraphQL queries is

-   <a href="https://gen3.theanvil.io/query" class="uri">https://gen3.theanvil.io/query</a>

Package installation and loading
--------------------------------

If necessary, install the Gen3 library

    if (!"Gen3" %in% rownames(installed.packages()))
        BiocManager::install("Bioconductor/Gen3")

Load the library into the current *R* session. Also useful for this
vignette is the dplyr package.

    library(Gen3)
    library(dplyr)

Authentication
--------------

Authenticate either for access mediated by AnVIL, or for direct access
to Gen3.

To use with an AnVIL account, log in to
<a href="https://anvil.terra.bio" class="uri">https://anvil.terra.bio</a>,
select the ‘Profile’ item on the ‘HAMBURGER’ dropdown, and use ‘NHGRI
AnVIL Data Commons Framework Services’ to link AnVIL with your Gen3
account. When on the AnVIL platform, or with the `gcloud` binary on your
search path and with `AnVIL::gcloud_cmd("auth", "list")` incidating the
correct account for AnVIL access, gain access to Gen3 with no arguments

    authenticate()

To obtain credentials for direct access to Gen3, visit
<a href="https://gen3.theanvil.io" class="uri">https://gen3.theanvil.io</a>,
login, and click on the profile icon. There you can create an access
credential as a JSON file. Download this file and remember its location.
Do not share this file with others. A convenient location to store the
credentials file is at this location:

    cache <- tools::R_user_dir("Gen3", "cache")
    credentials <- file.path(cache, "credentials.json")

Authenticate using these credentials with

    authenticate(credentials)

If a session has been idle for a while, the authentication credentials
may expire, resulting in a message like

    Error in .query(body) : Unauthorized (HTTP 401).

Simply renew credentials using the appropriate form of `authenticate()`
as described above.

Schema discovery and principles of data exploration
===================================================

Get schema types for Gen3. These contain the root entities for queries.

    ## { __schema { types { name } } }
    schema()

    ## [90m# A tibble: 11 x 1[39m
    ##    type_name               
    ##    [3m[90m<chr>[39m[23m                   
    ## [90m 1[39m data_release            
    ## [90m 2[39m root                    
    ## [90m 3[39m project                 
    ## [90m 4[39m program                 
    ## [90m 5[39m sequencing              
    ## [90m 6[39m core_metadata_collection
    ## [90m 7[39m sample                  
    ## [90m 8[39m subject                 
    ## [90m 9[39m family                  
    ## [90m10[39m discovery               
    ## [90m11[39m viewer

`schema("full")` provides a more complete list of schema entities. The
GraphQL query performed by this function is summariized in the comment.

Each schema entry is associated with fields; discover these with, e.g.,

    ## { __type(name: subject) { fields{ name } } }
    fields("subject")

    ## [90m# A tibble: 224 x 3[39m
    ##    type_name field                        type  
    ##    [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m                        [3m[90m<chr>[39m[23m 
    ## [90m 1[39m subject   id                           ID    
    ## [90m 2[39m subject   submitter_id                 String
    ## [90m 3[39m subject   type                         String
    ## [90m 4[39m subject   project_id                   String
    ## [90m 5[39m subject   created_datetime             String
    ## [90m 6[39m subject   updated_datetime             String
    ## [90m 7[39m subject   abnormal_wbc_history         String
    ## [90m 8[39m subject   abused_prescription_pill     String
    ## [90m 9[39m subject   active_encephalitis_at_death String
    ## [90m10[39m subject   active_meningitis_at_death   String
    ## [90m# … with 214 more rows[39m

`values()` performs a query against the database. The first argument is
the name of the entity to be retrieved; subsequent arguments are the
fields within that entity. The number of records returned is given by
`.n`, which has a default value of 10. Use `.n = 0` to retrieve all
entities.

    ## { subject(first: 50) { id project_id sex } }
    values("subject", "id", "project_id", "sex", .n = 50)

    ## [90m# A tibble: 50 x 3[39m
    ##    id                                   project_id sex   
    ##    [3m[90m<chr>[39m[23m                                [3m[90m<chr>[39m[23m      [3m[90m<chr>[39m[23m 
    ## [90m 1[39m 84115750-d24b-4d21-adf3-493e0ed235c9 CF-GTEx    Male  
    ## [90m 2[39m a45430bf-a5db-472e-9064-319e364fc646 CF-GTEx    Female
    ## [90m 3[39m 6ca83bf9-3974-4c60-b043-e686307aad42 CF-GTEx    Male  
    ## [90m 4[39m 34a97682-03f0-47a1-a432-638ae71fb5a8 CF-GTEx    Male  
    ## [90m 5[39m 741f5454-3c16-48da-8adf-281268432132 CF-GTEx    Male  
    ## [90m 6[39m f4f3bb48-ad05-4d85-8349-7ec112ab7004 CF-GTEx    Male  
    ## [90m 7[39m fd60edda-294c-429b-a1a0-0a8e3d77a420 CF-GTEx    Male  
    ## [90m 8[39m 7f169ccb-d30b-4a94-9410-3e4d9a2e196f CF-GTEx    Male  
    ## [90m 9[39m 99fde72a-bf88-48ca-ba67-f5c1c989712f CF-GTEx    Female
    ## [90m10[39m aedc8073-b97a-4a31-be35-c4a53d40470c CF-GTEx    Male  
    ## [90m# … with 40 more rows[39m

Bad queries return informative error messages

    values("subjects", "id")

    ## Error: query failed:
    ## category: Client error
    ## reason: Bad Request
    ## message: Client error: (400) Bad Request
    ## response:
    ##   Cannot query field "subjects" on type "Root". Did you mean "subject",
    ##     "project" or "_subject_count"?

    values("subject", "foo")

    ## Error: query failed:
    ## category: Client error
    ## reason: Bad Request
    ## message: Client error: (400) Bad Request
    ## response:
    ##   Cannot query field "foo" on type "subject".

An initial exploration
======================

Projects
--------

The first query we will do is to find all of the projects that we have
access to. `projects()` returns the fields `project_id`, `id`, and
`study_description` from all projects we have access to.

    ## { project(first: 0) { project_id id study_description } }
    projects()

    ## [90m# A tibble: 2 x 5[39m
    ##   project_id   id        study_description      .subjects_count .sequencings_co…
    ##   [3m[90m<chr>[39m[23m        [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m                            [3m[90m<int>[39m[23m            [3m[90m<int>[39m[23m
    ## [90m1[39m CF-GTEx      601f20e7… The aim of the Genoty…             981               46
    ## [90m2[39m open_access… d0a1de4b… The 1000 Genomes Proj…            [4m3[24m202              200

Subject, sample and sequencing entities
---------------------------------------

The main entities in Gen3 are subject, sample, and sequencing. Get the
fields available in the subject entity like this:

    ## { __type(name: subject) { fields { name type { name } } } }
    fields("subject") # any `name` of schema()

    ## [90m# A tibble: 224 x 3[39m
    ##    type_name field                        type  
    ##    [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m                        [3m[90m<chr>[39m[23m 
    ## [90m 1[39m subject   id                           ID    
    ## [90m 2[39m subject   submitter_id                 String
    ## [90m 3[39m subject   type                         String
    ## [90m 4[39m subject   project_id                   String
    ## [90m 5[39m subject   created_datetime             String
    ## [90m 6[39m subject   updated_datetime             String
    ## [90m 7[39m subject   abnormal_wbc_history         String
    ## [90m 8[39m subject   abused_prescription_pill     String
    ## [90m 9[39m subject   active_encephalitis_at_death String
    ## [90m10[39m subject   active_meningitis_at_death   String
    ## [90m# … with 214 more rows[39m

Similarly, the fields for ‘sample’ and ‘sequencing’ are

    ## { __type(name: sample) { fields { name type { name } } } }
    fields("sample")

    ## [90m# A tibble: 29 x 3[39m
    ##    type_name field                 type  
    ##    [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m                 [3m[90m<chr>[39m[23m 
    ## [90m 1[39m sample    id                    ID    
    ## [90m 2[39m sample    submitter_id          String
    ## [90m 3[39m sample    type                  String
    ## [90m 4[39m sample    project_id            String
    ## [90m 5[39m sample    created_datetime      String
    ## [90m 6[39m sample    updated_datetime      String
    ## [90m 7[39m sample    autolysis_score       String
    ## [90m 8[39m sample    bss_collection_site   String
    ## [90m 9[39m sample    current_material_type String
    ## [90m10[39m sample    dbgap_sample_id       String
    ## [90m# … with 19 more rows[39m

    ## { __type(name: sequencing) { fields { name type { name } } } }
    fields("sequencing")

    ## [90m# A tibble: 85 x 3[39m
    ##    type_name  field                 type  
    ##    [3m[90m<chr>[39m[23m      [3m[90m<chr>[39m[23m                 [3m[90m<chr>[39m[23m 
    ## [90m 1[39m sequencing id                    ID    
    ## [90m 2[39m sequencing submitter_id          String
    ## [90m 3[39m sequencing type                  String
    ## [90m 4[39m sequencing project_id            String
    ## [90m 5[39m sequencing created_datetime      String
    ## [90m 6[39m sequencing updated_datetime      String
    ## [90m 7[39m sequencing alignment_method      String
    ## [90m 8[39m sequencing alternative_aligments Int   
    ## [90m 9[39m sequencing analysis_freeze       String
    ## [90m10[39m sequencing analyte_type          String
    ## [90m# … with 75 more rows[39m

Query the value of fields, across all projects, with

    ## { sample(first: 10) { id rin_number } }
    values("sample", "id", "rin_number", .n = 10)

    ## [90m# A tibble: 10 x 2[39m
    ##    id                                   rin_number
    ##    [3m[90m<chr>[39m[23m                                     [3m[90m<dbl>[39m[23m
    ## [90m 1[39m d4c4573a-c629-4860-89c3-d84b8725d5cb        6.3
    ## [90m 2[39m 726e479e-2d6d-4a7e-bf4a-31455d1b9610        8  
    ## [90m 3[39m 1e027803-691c-43ac-b8fb-5028708cb587        7.5
    ## [90m 4[39m c341efb7-94d3-4788-997b-70820aa4cd21        7.6
    ## [90m 5[39m 6f59a691-4a7f-48e2-94be-9cc71439ee15        5.9
    ## [90m 6[39m 38a0d44a-6995-4d90-b506-1239aba87596        6.3
    ## [90m 7[39m f0e95e6e-be80-4149-b06a-b24a10a00f4f       [31mNA[39m  
    ## [90m 8[39m f752e7ea-e34b-41c0-ab74-2bcba60b1677       [31mNA[39m  
    ## [90m 9[39m 5e73ff7f-d659-440f-b866-c01ece569e41       [31mNA[39m  
    ## [90m10[39m d06ede98-60d5-4251-9bc0-147442f0dbf7       [31mNA[39m

    ## { sequencing(first: 10) { id file_name } }
    values("sequencing", "id", "file_name")

    ## [90m# A tibble: 10 x 2[39m
    ##    id                                   file_name                        
    ##    [3m[90m<chr>[39m[23m                                [3m[90m<chr>[39m[23m                            
    ## [90m 1[39m af47ce83-2567-448e-9f9e-ee190c8100a1 GTEX-1117F.readcounts.chrX.txt.gz
    ## [90m 2[39m 8b21c0e6-3a15-4597-b546-3a5d5b6b19ff GTEX-111CU.readcounts.chrX.txt.gz
    ## [90m 3[39m b49b408e-7798-4fe1-9060-7329951da2b0 GTEX-111FC.readcounts.chrX.txt.gz
    ## [90m 4[39m 205e10a7-bb3d-4bd3-88ec-9143a440d3c8 GTEX-1117F-0126.svs              
    ## [90m 5[39m 0cc9dd56-32ca-4c5b-907e-1c7d98b2bc1d GTEX-1117F-0226.svs              
    ## [90m 6[39m bad026f7-691c-44f6-9054-fa94ee3f3fc1 GTEX-111VG-0626.svs              
    ## [90m 7[39m 2bc0698f-d0fd-4e56-984b-c6e87fd8d3e6 GTEX-15RJE.readcounts.chrX.txt.gz
    ## [90m 8[39m 6c44e4fd-7d43-43fb-a159-d8731bfd8d89 GTEX-15SB6.readcounts.chrX.txt.gz
    ## [90m 9[39m bcaf6b36-0c71-4043-8b66-457d18b01e00 GTEX-15SDE.readcounts.chrX.txt.gz
    ## [90m10[39m 955b147d-2a2b-442f-8518-67956d502c5a GTEX-1117F-0326.svs

The Gen3 schema attempts to represent subjects (for example) from all
studies in a single entity, so the value of many fields may be missing
(`null` in the GraphQL respond, represented as `NA` in *R*).

    values("subject", "project_id", "weight", "age_of_onset")

    ## [90m# A tibble: 10 x 3[39m
    ##    project_id weight age_of_onset
    ##    [3m[90m<chr>[39m[23m       [3m[90m<dbl>[39m[23m [3m[90m<lgl>[39m[23m       
    ## [90m 1[39m CF-GTEx      213  [31mNA[39m          
    ## [90m 2[39m CF-GTEx      202. [31mNA[39m          
    ## [90m 3[39m CF-GTEx      174. [31mNA[39m          
    ## [90m 4[39m CF-GTEx      175  [31mNA[39m          
    ## [90m 5[39m CF-GTEx      200  [31mNA[39m          
    ## [90m 6[39m CF-GTEx      166  [31mNA[39m          
    ## [90m 7[39m CF-GTEx      263  [31mNA[39m          
    ## [90m 8[39m CF-GTEx      202. [31mNA[39m          
    ## [90m 9[39m CF-GTEx      146. [31mNA[39m          
    ## [90m10[39m CF-GTEx      197. [31mNA[39m

Direct use of GraphQL
=====================

Use GraphQL directly for more complicated queries, e.g., filtering
parameters.

For example queries the `subject` field restricted to those with the
“open\_access-1000Genomes” `project_id` for four values: `id`, `sex`,
`population`, and `submitter_id`. Using `first: 0` returns all records.

    query <- '{
        subject(
            project_id: "open_access-1000Genomes"
            first: 0
        ) {
            id
            sex
            population
            submitter_id
        }
    }'
    result <- query_graphql(query)

The return value is a list with structure like that of the query. values
for each subject have been simiplified to a tibble. The elements of the
list are accessible using standard *R* operations

    result$subject

    ## [90m# A tibble: 3,202 x 4[39m
    ##    id                                   population sex    submitter_id
    ##    [3m[90m<chr>[39m[23m                                [3m[90m<chr>[39m[23m      [3m[90m<chr>[39m[23m  [3m[90m<chr>[39m[23m       
    ## [90m 1[39m 987efda6-b4cf-4148-b2a0-1d64b471d625 STU        Female HG03894     
    ## [90m 2[39m a59edd9e-8d43-4a56-8352-c1e532a6ec1e STU        Male   HG03896     
    ## [90m 3[39m 28401aec-4c28-4e08-ab12-efe57ed3bc10 STU        Female HG03898     
    ## [90m 4[39m 6f36ecee-00fb-411e-98b7-37a168e5165e STU        Male   HG03899     
    ## [90m 5[39m fde92d12-c014-4d53-b2c0-77ece237e44b STU        Female HG03897     
    ## [90m 6[39m 0465a439-dfca-44ce-95aa-24e9a19c8157 IBS        Female HG01679     
    ## [90m 7[39m 86c89cad-3656-4cce-af5f-015db00906d2 GBR        Male   HG00242     
    ## [90m 8[39m 36881c4a-b563-4de6-aa31-2c326f2c704a GBR        Male   HG00243     
    ## [90m 9[39m c4df7392-6499-4bea-92c9-221c58fab73b GBR        Male   HG00244     
    ## [90m10[39m 85a7a071-18e7-44b3-941b-9c428c4c5dd9 GBR        Female HG00245     
    ## [90m# … with 3,192 more rows[39m

The following query retrieves the `id` and `tissue_type` of all samples
in GTEx.

    query <- '{
        sample(
            project_id: "CF-GTEx"
            first: 0
        ) {
            id
            tissue_type
        }
    }'
    result <- query_graphql(query)
    result$sample

    ## [90m# A tibble: 48,678 x 2[39m
    ##    id                                   tissue_type   
    ##    [3m[90m<chr>[39m[23m                                [3m[90m<chr>[39m[23m         
    ## [90m 1[39m d4c4573a-c629-4860-89c3-d84b8725d5cb Adipose Tissue
    ## [90m 2[39m 726e479e-2d6d-4a7e-bf4a-31455d1b9610 Muscle        
    ## [90m 3[39m 1e027803-691c-43ac-b8fb-5028708cb587 Nerve         
    ## [90m 4[39m c341efb7-94d3-4788-997b-70820aa4cd21 Blood Vessel  
    ## [90m 5[39m 6f59a691-4a7f-48e2-94be-9cc71439ee15 Brain         
    ## [90m 6[39m 38a0d44a-6995-4d90-b506-1239aba87596 Pituitary     
    ## [90m 7[39m f0e95e6e-be80-4149-b06a-b24a10a00f4f Blood         
    ## [90m 8[39m f752e7ea-e34b-41c0-ab74-2bcba60b1677 Blood         
    ## [90m 9[39m 5e73ff7f-d659-440f-b866-c01ece569e41 Blood         
    ## [90m10[39m d06ede98-60d5-4251-9bc0-147442f0dbf7 Blood         
    ## [90m# … with 48,668 more rows[39m

The tibble is easily explored using standard tidy paradigms, e.g.,

    result$sample %>%
        count(tissue_type) %>%
        arrange(desc(n))

    ## [90m# A tibble: 31 x 2[39m
    ##    tissue_type        n
    ##    [3m[90m<chr>[39m[23m          [3m[90m<int>[39m[23m
    ## [90m 1[39m [31mNA[39m             [4m2[24m[4m6[24m228
    ## [90m 2[39m Blood           [4m3[24m480
    ## [90m 3[39m Brain           [4m3[24m326
    ## [90m 4[39m Skin            [4m2[24m011
    ## [90m 5[39m Esophagus       [4m1[24m568
    ## [90m 6[39m Blood Vessel    [4m1[24m473
    ## [90m 7[39m Adipose Tissue  [4m1[24m327
    ## [90m 8[39m Heart           [4m1[24m036
    ## [90m 9[39m Muscle          [4m1[24m017
    ## [90m10[39m Lung             826
    ## [90m# … with 21 more rows[39m

Syntax errors return an error from the server

    query <- '{ sample { id }'
    query_graphql(query)

    ## Error: query failed:
    ## category: Client error
    ## reason: Bad Request
    ## message: Client error: (400) Bad Request
    ## response:
    ##   Syntax Error GraphQL request (1:16) Expected Name, found EOF
    ## 
    ##   1: { sample { id } ^

Session information
===================

    sessionInfo()

    ## R version 4.0.2 (2020-06-22)
    ## Platform: x86_64-pc-linux-gnu (64-bit)
    ## Running under: Ubuntu 20.04.1 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.9.0
    ## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.9.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] dplyr_1.0.1 Gen3_0.0.8 
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] knitr_1.29           magrittr_1.5         tidyselect_1.1.0    
    ##  [4] R6_2.4.1             rlang_0.4.7          fansi_0.4.1         
    ##  [7] httr_1.4.2           stringr_1.4.0        tools_4.0.2         
    ## [10] xfun_0.16            utf8_1.1.4           cli_2.0.2           
    ## [13] lambda.r_1.2.4       futile.logger_1.4.3  ellipsis_0.3.1      
    ## [16] htmltools_0.5.0      assertthat_0.2.1     yaml_2.2.1          
    ## [19] AnVIL_1.1.14         digest_0.6.25        tibble_3.0.3        
    ## [22] lifecycle_0.2.0      crayon_1.3.4         purrr_0.3.4         
    ## [25] formatR_1.7          vctrs_0.3.2          futile.options_1.0.1
    ## [28] rapiclient_0.1.3     curl_4.3             glue_1.4.1          
    ## [31] evaluate_0.14        rmarkdown_2.3        stringi_1.4.6       
    ## [34] pillar_1.4.6         compiler_4.0.2       generics_0.0.2      
    ## [37] jsonlite_1.7.0       pkgconfig_2.0.3
