.GEN3_GRAPHQL <- "https://gen3.theanvil.io/api/v0/submission/graphql/"
.GEN3_FLATQL <-  "https://gen3.theanvil.io/guppy/graphql/"

#' @importFrom tibble as_tibble
#'
#' @importFrom httr add_headers http_error http_status
.query_graphql <-
    function(body)
{
    token <- .BEARER_TOKEN()
    header <- add_headers(Authorization=paste("Bearer", token))

    response <- POST(.GEN3_GRAPHQL, body = body, encode="json", header)
    if (http_error(response)) {
        status <- http_status(response)
        msg0 <- paste0(names(status), ": ", unlist(status, use.names = FALSE))
        msg1 <- content(response)$errors
        stop(
            "query failed:\n",
            paste0(msg0, collapse = "\n"), "\n",
            "response:\n",
            paste(
                strwrap(content(response)$errors, indent = 2, exdent = 4),
                collapse = "\n"
            ),
            call. = FALSE
        )
    }

    content(response, "text", encoding = "UTF-8")
}

#' @rdname query
#'
#' @title Discover and query Gen3 resources
#'
#' @description `projects()` returns projects available to the
#'     currently authenticated user
#'
#' @return `projects()` returns a tibble with project_id, id, and
#'     study_description. There are as many rows as there are projects
#'     accessbile to the current user.
#'
#' @examples
#' ## Authenticate first
#' cache <- tools::R_user_dir("Gen3", "cache")
#' credentials <- file.path(cache, "credentials.json")
#'
#' ## only run examples if credentials file exists
#' stopifnot(
#'     `no credentials file, cannot authenticate` = file.exists(credentials)
#' )
#'
#' authenticate(credentials)
#' projects()
#'
#' @importFrom dplyr mutate "%>%"
#'
#' @export
projects <-
    function()
{
    values("project", "project_id", "id", "study_description", .n = 0L) %>%
        mutate(study_description = trimws(.data$study_description))
}

#' @rdname query
#'
#' @description `schema()` returns all type names (objects) defined in
#'     the Gen3 schema. Type names form the basis of queries.
#'
#' @param as `character(1)` either `"brief"` (default) or `"full"`.
#'
#'     For `schema()`, `"brief"` filters on type names that start with
#'     a lower-case letter (this ad hoc criterion seems to identify
#'     type names that are useful to the user). `"full"` returns all
#'     type names defined in the schema.
#'
#' @return `schema()` returns a tibble with with a single columm
#'     (`"name"`) corresponding to the type names available in Gen3.
#'
#' @examples
#' schema()
#'
#' @importFrom jsonlite toJSON
#'
#' @importFrom rlang .data
#'
#' @importFrom dplyr rename bind_cols filter "%>%"
#'
#' @export
schema <-
    function(as = c("brief", "full"))
{
    as <- match.arg(as)

    body <- '{"query":"{__schema { types{name} } }"}'
    content <- .query_graphql(body)
    types <- fromJSON(content)[[c("data", "__schema", "types")]]
    tbl <-
        as_tibble(types) %>%
        rename(type_name = "name")

    switch(
        as,
        brief = tbl %>% filter(substr(.data$type_name, 1, 1) %in% letters),
        tbl
    )
}

#' @rdname query
#'
#' @description `fields()` returns fields defined on the type name. A
#'     field has associated values that can be retrieved by queries.
#'
#' @param type_name `character(1)` name of the type to be queried.
#'
#' @param as
#'
#'     for `fields()`, `"brief"` returns fields that do not start with
#'     an underscore. `"full"` returns all fields.
#'
#' @return `fields()` returns a tibble with columns `type_name`,
#'     `field` (name of corresponding fields in type name) and `type`
#'     (type of field, e.g., String, Int).
#'
#' @examples
#' fields("subject")
#'
#' @export
fields <-
    function(type_name, as = c("brief", "full"))
{
    stopifnot(.is_scalar_character(type_name))
    as <- match.arg(as)

    q <- sprintf(
        '{__type(name: "%s") { fields { name type { name } } } }',
        type_name
    )
    myl <- list(query=q)
    body <- toJSON(myl, auto_unbox=TRUE)

    content <- .query_graphql(body)
    fields <- fromJSON(content)[[c("data", "__type", "fields")]]
    tbl <-
        bind_cols(type_name = type_name, as_tibble(fields)) %>%
        mutate(type = unlist(.data$type)) %>%
        rename(field = "name")

    switch(
        as,
        brief = tbl %>% filter(!startsWith(.data$field, "_")),
        tbl
    )
}

#' @rdname query
#'
#' @description `values()` returns values corresponding to fields of
#'     `type_name`. Each row represents a record in the database.
#'
#' @param ... `character(1)` field(s) to be queried.
#'
#' @param .n integer(1) number of records to retieve. The special
#'     value `.n = 0` retrieves all records.
#'
#' @return `values()` returns a tibble with type_name and field names
#'     as columns, with one row for each record queried.
#'
#' @examples
#' values("subject", "id", "sex")
#'
#' @export
values <-
    function(type_name, ..., .n = 10)
{
    stopifnot(
        .is_scalar_character(type_name),
        `no fields specified` = length(list(...)) >= 1L,
        .is_scalar_numeric(.n)
    )
    if (is.infinite(.n))
        .n <- 0L

    q <- sprintf(
        '{ %s( first:%d ) { %s } }',
        type_name,
        .n,
        paste(..., collapse = " ")
    )
    myl <- list(query = q)
    body <- toJSON(myl, auto_unbox=TRUE)

    content <- .query_graphql(body)
    subject <- fromJSON(content)[[c("data", type_name)]]
    as_tibble(subject)
}

#' @rdname query
#'
#' @description `query_graphql()` allows arbitrary queries against the
#'     graphql database.
#'
#' @param query character(1) valid graphql query to be evaluated by
#'     the database.
#'
#' @return `query_graphql()` returns JSON-like list-of-lists following
#'     the structure of the query, but with terminal data.frame-like
#'     collections simplified to a tibbles.
#'
#' @examples
#' query <- '{
#'     subject(
#'         project_id: "open_access-1000Genomes"
#'         first: 0
#'     ) {
#'         id
#'         sex
#'         population
#'         submitter_id
#'     }
#' }'
#' result <- query_graphql(query)
#' result
#'
#' @export
query_graphql <-
    function(query)
{
    stopifnot(.is_scalar_character(query))

    body <- gsub("[[:space:]]+", " ", query)
    json <- toJSON(list(query = body), auto_unbox = TRUE)
    content <- .query_graphql(json)
    result <- fromJSON(content)[["data"]]
    .tibbilize_list(result)
}
