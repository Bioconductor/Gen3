.GEN3_CREDENTIALS <- "https://gen3.theanvil.io/user/credentials/cdis/access_token"

.BEARER_TOKEN <- local({
    token <- NULL
    function(value) {
        if (!missing(value))
            token <<- value
        token
    }
})

#' @importFrom httr POST stop_for_status content
#'
#' @importFrom jsonlite fromJSON
#'
#' @export
authenticate <-
    function(file)
{
    stopifnot(file.exists(file))

    gen3token <- fromJSON(file)
    url <- .GEN3_CREDENTIALS

    response <- POST(url, body=gen3token, encode="json")
    stop_for_status(response)

    content <- content(response, "text", encoding = "UTF-8")
    token <- fromJSON(content)$access_token
    value <- .BEARER_TOKEN(token)

    invisible(value)
}        
