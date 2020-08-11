# Accessing Gen3 in the AnVIL
{:.no_toc}

<p class="author-name">BJ Stubbs and Martin Morgan</p>

## Contents
{:.no_toc}

-   [Introduction](#introduction)
    -   [Package installation and
        loading](#package-installation-and-loading)
    -   [Authentication](#authentication)
-   [Schema discovery and principles of data
    exploration](#schema-discovery-and-principles-of-data-exploration)
-   [An initial exploration](#an-initial-exploration)
    -   [Projects](#projects)
    -   [Subject, sample and sequencing
        entities](#subject-sample-and-sequencing-entities)
-   [Direct use of GraphQL](#direct-use-of-graphql)
-   [Session information](#session-information)
{:toc}

## Introduction

This is a demo of how to login and query Gen3 from R.

This is based on:

-   <a href="https://gen3.org/resources/user/using-api/" class="uri">https://gen3.org/resources/user/using-api/</a>
-   <a href="https://gen3.org/resources/developer/flat-model-api/" class="uri">https://gen3.org/resources/developer/flat-model-api/</a>
-   <a href="https://graphql.org/learn/queries/" class="uri">https://graphql.org/learn/queries/</a>
-   <a href="https://graphql.org/learn/introspection/" class="uri">https://graphql.org/learn/introspection/</a>

A very useful facility for formulating GraphQL queries is

-   <a href="https://gen3.theanvil.io/query" class="uri">https://gen3.theanvil.io/query</a>

### Package installation and loading

If necessary, install the Gen3 library

    if (!"Gen3" %in% rownames(installed.packages()))
        BiocManager::install("Bioconductor/Gen3")

Load the library into the current *R* session. Also useful for this
vignette is the dplyr package.

    library(Gen3)
    library(dplyr)

### Authentication

Authenticate either for direct access to Gen3, or for access mediated by
AnVIL.

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

To use with an AnVIL account, log in to
<a href="https://anvil.terra.bio" class="uri">https://anvil.terra.bio</a>,
select the ‘Profile’ item on the ‘HAMBURGER’ dropdown, and use ‘NHGRI
AnVIL Data Commons Framework Services’ to link AnVIL with your Gen3
account. When on the AnVIL platform, or with the `gcloud` binary on your
search path and with `AnVIL::gcloud_cmd("auth", "list")` incidating the
correct account for AnVIL access, gain access to Gen3 with no arguments

    authenticate()

If a session has been idle for a while, the authentication credentials
may expire, resulting in a message like

    Error in .query(body) : Unauthorized (HTTP 401).

Simply renew credentials using the appropriate form of `authenticate()`
as described above.

## Schema discovery and principles of data exploration

Get schema types for Gen3. These contain the root entities for queries.

    ## { __schema { types { name } } }
    schema()

    ## # A tibble: 11 x 1
    ##    type_name               
    ##    <chr>                   
    ##  1 data_release            
    ##  2 root                    
    ##  3 project                 
    ##  4 program                 
    ##  5 sequencing              
    ##  6 core_metadata_collection
    ##  7 sample                  
    ##  8 subject                 
    ##  9 family                  
    ## 10 discovery               
    ## 11 viewer

`schema("full")` provides a more complete list of schema entities. The
GraphQL query performed by this function is summariized in the comment.

Each schema entry is associated with fields; discover these with, e.g.,

    ## { __type(name: subject) { fields{ name } } }
    fields("subject")

    ## # A tibble: 224 x 3
    ##    type_name field                        type  
    ##    <chr>     <chr>                        <chr> 
    ##  1 subject   id                           ID    
    ##  2 subject   submitter_id                 String
    ##  3 subject   type                         String
    ##  4 subject   project_id                   String
    ##  5 subject   created_datetime             String
    ##  6 subject   updated_datetime             String
    ##  7 subject   abnormal_wbc_history         String
    ##  8 subject   abused_prescription_pill     String
    ##  9 subject   active_encephalitis_at_death String
    ## 10 subject   active_meningitis_at_death   String
    ## # … with 214 more rows

`values()` performs a query against the database. The first argument is
the name of the entity to be retrieved; subsequent arguments are the
fields within that entity. The number of records returned is given by
`.n`, which has a default value of 10. Use `.n = 0` to retrieve all
entities.

    ## { subject(first: 50) { id project_id sex } }
    values("subject", "id", "project_id", "sex", .n = 50)

    ## # A tibble: 50 x 3
    ##    id                                   project_id sex   
    ##    <chr>                                <chr>      <chr> 
    ##  1 84115750-d24b-4d21-adf3-493e0ed235c9 CF-GTEx    Male  
    ##  2 a45430bf-a5db-472e-9064-319e364fc646 CF-GTEx    Female
    ##  3 6ca83bf9-3974-4c60-b043-e686307aad42 CF-GTEx    Male  
    ##  4 34a97682-03f0-47a1-a432-638ae71fb5a8 CF-GTEx    Male  
    ##  5 741f5454-3c16-48da-8adf-281268432132 CF-GTEx    Male  
    ##  6 f4f3bb48-ad05-4d85-8349-7ec112ab7004 CF-GTEx    Male  
    ##  7 fd60edda-294c-429b-a1a0-0a8e3d77a420 CF-GTEx    Male  
    ##  8 7f169ccb-d30b-4a94-9410-3e4d9a2e196f CF-GTEx    Male  
    ##  9 99fde72a-bf88-48ca-ba67-f5c1c989712f CF-GTEx    Female
    ## 10 aedc8073-b97a-4a31-be35-c4a53d40470c CF-GTEx    Male  
    ## # … with 40 more rows

## An initial exploration

### Projects

The first query we will do is to find all of the projects that we have
access to. `projects()` returns the fields `project_id`, `id`, and
`study_description` from all projects we have access to.

    ## { project(first: 0) { project_id id study_description } }
    projects()

    ## # A tibble: 2 x 3
    ##   id                  project_id      study_description                         
    ##   <chr>               <chr>           <chr>                                     
    ## 1 601f20e7-1ea2-539b… CF-GTEx         The aim of the Genotype-Tissue Expression…
    ## 2 d0a1de4b-f635-5923… open_access-10… The 1000 Genomes Project ran between 2008…

### Subject, sample and sequencing entities

The main entities in Gen3 are subject, sample, and sequencing. Get the
fields available in the subject entity like this:

    ## { __type(name: subject) { fields { name } } }
    fields("subject") # any `name` of schema()

    ## # A tibble: 224 x 3
    ##    type_name field                        type  
    ##    <chr>     <chr>                        <chr> 
    ##  1 subject   id                           ID    
    ##  2 subject   submitter_id                 String
    ##  3 subject   type                         String
    ##  4 subject   project_id                   String
    ##  5 subject   created_datetime             String
    ##  6 subject   updated_datetime             String
    ##  7 subject   abnormal_wbc_history         String
    ##  8 subject   abused_prescription_pill     String
    ##  9 subject   active_encephalitis_at_death String
    ## 10 subject   active_meningitis_at_death   String
    ## # … with 214 more rows

Similarly, the fields for ‘sample’ and ‘sequencing’ are

    ## { __type(name: sample) { fields { name } } }
    fields("sample")

    ## # A tibble: 29 x 3
    ##    type_name field                 type  
    ##    <chr>     <chr>                 <chr> 
    ##  1 sample    id                    ID    
    ##  2 sample    submitter_id          String
    ##  3 sample    type                  String
    ##  4 sample    project_id            String
    ##  5 sample    created_datetime      String
    ##  6 sample    updated_datetime      String
    ##  7 sample    autolysis_score       String
    ##  8 sample    bss_collection_site   String
    ##  9 sample    current_material_type String
    ## 10 sample    dbgap_sample_id       String
    ## # … with 19 more rows

    ## { __type(name: sequencing) { fields { name } } }
    fields("sequencing")

    ## # A tibble: 85 x 3
    ##    type_name  field                 type  
    ##    <chr>      <chr>                 <chr> 
    ##  1 sequencing id                    ID    
    ##  2 sequencing submitter_id          String
    ##  3 sequencing type                  String
    ##  4 sequencing project_id            String
    ##  5 sequencing created_datetime      String
    ##  6 sequencing updated_datetime      String
    ##  7 sequencing alignment_method      String
    ##  8 sequencing alternative_aligments Int   
    ##  9 sequencing analysis_freeze       String
    ## 10 sequencing analyte_type          String
    ## # … with 75 more rows

Query the value of fields, across all projects, with

    ## { sample(first: 10) { id rin_number } }
    values("sample", "id", "rin_number", .n = 10)

    ## # A tibble: 10 x 2
    ##    id                                   rin_number
    ##    <chr>                                     <dbl>
    ##  1 d4c4573a-c629-4860-89c3-d84b8725d5cb        6.3
    ##  2 726e479e-2d6d-4a7e-bf4a-31455d1b9610        8  
    ##  3 1e027803-691c-43ac-b8fb-5028708cb587        7.5
    ##  4 c341efb7-94d3-4788-997b-70820aa4cd21        7.6
    ##  5 6f59a691-4a7f-48e2-94be-9cc71439ee15        5.9
    ##  6 38a0d44a-6995-4d90-b506-1239aba87596        6.3
    ##  7 f0e95e6e-be80-4149-b06a-b24a10a00f4f       NA  
    ##  8 f752e7ea-e34b-41c0-ab74-2bcba60b1677       NA  
    ##  9 5e73ff7f-d659-440f-b866-c01ece569e41       NA  
    ## 10 d06ede98-60d5-4251-9bc0-147442f0dbf7       NA

    ## { sequencing(first: 10) { id file_name } }
    values("sequencing", "id", "file_name")

    ## # A tibble: 10 x 2
    ##    file_name                         id                                  
    ##    <chr>                             <chr>                               
    ##  1 GTEX-1117F.readcounts.chrX.txt.gz af47ce83-2567-448e-9f9e-ee190c8100a1
    ##  2 GTEX-111CU.readcounts.chrX.txt.gz 8b21c0e6-3a15-4597-b546-3a5d5b6b19ff
    ##  3 GTEX-111FC.readcounts.chrX.txt.gz b49b408e-7798-4fe1-9060-7329951da2b0
    ##  4 GTEX-1117F-0126.svs               205e10a7-bb3d-4bd3-88ec-9143a440d3c8
    ##  5 GTEX-1117F-0226.svs               0cc9dd56-32ca-4c5b-907e-1c7d98b2bc1d
    ##  6 GTEX-111VG-0626.svs               bad026f7-691c-44f6-9054-fa94ee3f3fc1
    ##  7 GTEX-15RJE.readcounts.chrX.txt.gz 2bc0698f-d0fd-4e56-984b-c6e87fd8d3e6
    ##  8 GTEX-15SB6.readcounts.chrX.txt.gz 6c44e4fd-7d43-43fb-a159-d8731bfd8d89
    ##  9 GTEX-15SDE.readcounts.chrX.txt.gz bcaf6b36-0c71-4043-8b66-457d18b01e00
    ## 10 GTEX-1117F-0326.svs               955b147d-2a2b-442f-8518-67956d502c5a

The Gen3 schema attempts to represent subjects (for example) from all
studies in a single entity, so the value of many fields may be missing
(`null` in the GraphQL respond, represented as `NA` in *R*).

    values("subject", "project_id", "weight", "age_of_onset")

    ## # A tibble: 10 x 3
    ##    age_of_onset project_id weight
    ##    <lgl>        <chr>       <dbl>
    ##  1 NA           CF-GTEx      213 
    ##  2 NA           CF-GTEx      202.
    ##  3 NA           CF-GTEx      174.
    ##  4 NA           CF-GTEx      175 
    ##  5 NA           CF-GTEx      200 
    ##  6 NA           CF-GTEx      166 
    ##  7 NA           CF-GTEx      263 
    ##  8 NA           CF-GTEx      202.
    ##  9 NA           CF-GTEx      146.
    ## 10 NA           CF-GTEx      197.

## Direct use of GraphQL

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

    ## # A tibble: 3,202 x 4
    ##    id                                   population sex    submitter_id
    ##    <chr>                                <chr>      <chr>  <chr>       
    ##  1 987efda6-b4cf-4148-b2a0-1d64b471d625 STU        Female HG03894     
    ##  2 a59edd9e-8d43-4a56-8352-c1e532a6ec1e STU        Male   HG03896     
    ##  3 28401aec-4c28-4e08-ab12-efe57ed3bc10 STU        Female HG03898     
    ##  4 6f36ecee-00fb-411e-98b7-37a168e5165e STU        Male   HG03899     
    ##  5 fde92d12-c014-4d53-b2c0-77ece237e44b STU        Female HG03897     
    ##  6 0465a439-dfca-44ce-95aa-24e9a19c8157 IBS        Female HG01679     
    ##  7 86c89cad-3656-4cce-af5f-015db00906d2 GBR        Male   HG00242     
    ##  8 36881c4a-b563-4de6-aa31-2c326f2c704a GBR        Male   HG00243     
    ##  9 c4df7392-6499-4bea-92c9-221c58fab73b GBR        Male   HG00244     
    ## 10 85a7a071-18e7-44b3-941b-9c428c4c5dd9 GBR        Female HG00245     
    ## # … with 3,192 more rows

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

    ## # A tibble: 48,678 x 2
    ##    id                                   tissue_type   
    ##    <chr>                                <chr>         
    ##  1 d4c4573a-c629-4860-89c3-d84b8725d5cb Adipose Tissue
    ##  2 726e479e-2d6d-4a7e-bf4a-31455d1b9610 Muscle        
    ##  3 1e027803-691c-43ac-b8fb-5028708cb587 Nerve         
    ##  4 c341efb7-94d3-4788-997b-70820aa4cd21 Blood Vessel  
    ##  5 6f59a691-4a7f-48e2-94be-9cc71439ee15 Brain         
    ##  6 38a0d44a-6995-4d90-b506-1239aba87596 Pituitary     
    ##  7 f0e95e6e-be80-4149-b06a-b24a10a00f4f Blood         
    ##  8 f752e7ea-e34b-41c0-ab74-2bcba60b1677 Blood         
    ##  9 5e73ff7f-d659-440f-b866-c01ece569e41 Blood         
    ## 10 d06ede98-60d5-4251-9bc0-147442f0dbf7 Blood         
    ## # … with 48,668 more rows

The tibble is easily explored using standard tidy paradigms, e.g.,

    result$sample %>%
        count(tissue_type) %>%
        arrange(desc(n))

    ## # A tibble: 31 x 2
    ##    tissue_type        n
    ##    <chr>          <int>
    ##  1 <NA>           26228
    ##  2 Blood           3480
    ##  3 Brain           3326
    ##  4 Skin            2011
    ##  5 Esophagus       1568
    ##  6 Blood Vessel    1473
    ##  7 Adipose Tissue  1327
    ##  8 Heart           1036
    ##  9 Muscle          1017
    ## 10 Lung             826
    ## # … with 21 more rows

Syntax errors return an error from the server

    query <- '{ sample { id }'
    tryCatch(query_graphql(query), error = identity)

    ## <http_400 in .query_graphql(json): Bad Request (HTTP 400).>

## Session information

    sessionInfo()

    ## R version 4.0.2 Patched (2020-06-24 r78747)
    ## Platform: x86_64-apple-darwin17.7.0 (64-bit)
    ## Running under: macOS High Sierra 10.13.6
    ## 
    ## Matrix products: default
    ## BLAS:   /Users/ma38727/bin/R-4-0-branch/lib/libRblas.dylib
    ## LAPACK: /Users/ma38727/bin/R-4-0-branch/lib/libRlapack.dylib
    ## 
    ## locale:
    ## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] dplyr_1.0.0      Gen3_0.0.6       BiocStyle_2.17.0
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] compiler_4.0.2       pillar_1.4.6         formatR_1.7         
    ##  [4] BiocManager_1.30.10  futile.logger_1.4.3  futile.options_1.0.1
    ##  [7] tools_4.0.2          digest_0.6.25        jsonlite_1.7.0      
    ## [10] evaluate_0.14        lifecycle_0.2.0      tibble_3.0.3        
    ## [13] pkgconfig_2.0.3      rlang_0.4.7          cli_2.0.2           
    ## [16] curl_4.3             yaml_2.2.1           xfun_0.16           
    ## [19] stringr_1.4.0        httr_1.4.2           knitr_1.29          
    ## [22] generics_0.0.2       vctrs_0.3.2          tidyselect_1.1.0    
    ## [25] glue_1.4.1           R6_2.4.1             fansi_0.4.1         
    ## [28] rmarkdown_2.3        bookdown_0.20        purrr_0.3.4         
    ## [31] lambda.r_1.2.4       magrittr_1.5         htmltools_0.5.0     
    ## [34] ellipsis_0.3.1       rapiclient_0.1.3     assertthat_0.2.1    
    ## [37] utf8_1.1.4           stringi_1.4.6        AnVIL_1.1.14        
    ## [40] crayon_1.3.4
