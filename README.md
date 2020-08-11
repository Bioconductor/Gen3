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

`schema("full")` provides a more complete list of schema entities. The
GraphQL query performed by this function is summariized in the comment.

Each schema entry is associated with fields; discover these with, e.g.,

    ## { __type(name: subject) { fields{ name } } }
    fields("subject")

`values()` performs a query against the database. The first argument is
the name of the entity to be retrieved; subsequent arguments are the
fields within that entity. The number of records returned is given by
`.n`, which has a default value of 10. Use `.n = 0` to retrieve all
entities.

    ## { subject(first: 50) { id project_id sex } }
    values("subject", "id", "project_id", "sex", .n = 50)

Bad queries return informative error messages

    values("subjects", "id")
    values("subject", "foo")

An initial exploration
======================

Projects
--------

The first query we will do is to find all of the projects that we have
access to. `projects()` returns the fields `project_id`, `id`, and
`study_description` from all projects we have access to.

    ## { project(first: 0) { project_id id study_description } }
    projects()

Subject, sample and sequencing entities
---------------------------------------

The main entities in Gen3 are subject, sample, and sequencing. Get the
fields available in the subject entity like this:

    ## { __type(name: subject) { fields { name type { name } } } }
    fields("subject") # any `name` of schema()

Similarly, the fields for ‘sample’ and ‘sequencing’ are

    ## { __type(name: sample) { fields { name type { name } } } }
    fields("sample")

    ## { __type(name: sequencing) { fields { name type { name } } } }
    fields("sequencing")

Query the value of fields, across all projects, with

    ## { sample(first: 10) { id rin_number } }
    values("sample", "id", "rin_number", .n = 10)

    ## { sequencing(first: 10) { id file_name } }
    values("sequencing", "id", "file_name")

The Gen3 schema attempts to represent subjects (for example) from all
studies in a single entity, so the value of many fields may be missing
(`null` in the GraphQL respond, represented as `NA` in *R*).

    values("subject", "project_id", "weight", "age_of_onset")

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

The tibble is easily explored using standard tidy paradigms, e.g.,

    result$sample %>%
        count(tissue_type) %>%
        arrange(desc(n))

Syntax errors return an error from the server

    query <- '{ sample { id }'
    query_graphql(query)

Session information
===================

    sessionInfo()
