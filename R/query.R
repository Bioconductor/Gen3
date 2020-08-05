.GEN3_GRAPHQL <- "https://gen3.theanvil.io/api/v0/submission/graphql/"

#' @importFrom tibble as_tibble
#'
#' @importFrom httr add_headers
.query <-
    function(body)
{
    token <- .BEARER_TOKEN()
    header <- add_headers(Authorization=paste("Bearer", token))

    response <- POST(.GEN3_GRAPHQL, body = body, encode="json", header)
    stop_for_status(response)

    content(response, "text", encoding = "UTF-8")
}

#' @export
projects <-
    function()
{
    body <- '{ "query" : "{ project(first:0) {project_id id} }" }'
    content <- .query(body)
    project <- fromJSON(content)[[c("data", "project")]]
    as_tibble(project)
}

#' @importFrom jsonlite toJSON
#'
#' @importFrom rlang .data
#'
#' @importFrom dplyr filter "%>%"
#'
#' @export
schema <-
    function(as = c("brief", "full"))
{
    as <- match.arg(as)

    body <- '{"query":"{__schema { types{name} } }"}'
    content <- .query(body)
    types <- fromJSON(content)[[c("data", "__schema", "types")]]
    tbl <- as_tibble(types)

    switch(
        as,
        brief = tbl %>% filter(substr(.data$name, 1, 1) %in% letters),
        tbl
    )
}

#' @export
fields <-
    function(type_name, as = c("brief", "full"))
{
    stopifnot(.is_scalar_character(type_name))
    as <- match.arg(as)

    q <- sprintf('{__type(name: "%s") {name fields{name}}}', type_name)
    myl <- list(query=q)
    body <- toJSON(myl, auto_unbox=TRUE)

    content <- .query(body)
    fields <- fromJSON(content)[[c("data", "__type", "fields")]]
    tbl <- as_tibble(fields)

    switch(
        as,
        brief = tbl %>% filter(!startsWith(.data$name, "_")),
        tbl
    )
}

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

    content <- .query(body)
    subject <- fromJSON(content)[[c("data", type_name)]]
    as_tibble(subject)
}
