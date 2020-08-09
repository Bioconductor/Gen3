.GEN3_CREDENTIALS <- "https://gen3.theanvil.io/user/credentials/cdis/access_token"

.BEARER_TOKEN <- local({
    token <- NULL
    function(value) {
        if (!missing(value))
            token <<- value
        if (is.null(token))
            stop(
                "please 'authenticate()' before preforming queries",
                call. = FALSE
            )
        token
    }
})

#' @rdname authenticate
#'
#' @title Authenticate against gen3.theanvil.io
#'
#' @description Authenticate against gen3.theanvil.io using
#'     credentials obtained external to _R_. Authentication persis for
#'     the duration of the _R_ session, or until authentication
#'     expires using criteria defined on the server.
#'
#' @param file character(1) file path to json credentials, as
#'     described in the 'details' section.
#'
#' @details To obtain credentials, visit https://gen3.theanvil.io,
#'     login, and click on the profile icon. There you can create an
#'     access credential as a JSON file. Download this file and
#'     remember its location. Do not share this file with others.
#'
#'     A convenient location to store the credentials file is at this
#'     location:
#'
#'         cache <- tools::R_user_dir("Gen3", "cache")
#'         credentials <- file.path(cache, "credentials.json")
#'
#' @return The bearer token used for authentication, invisibly
#' 
#' @examples
#' ## Authenticate first
#' cache <- tools::R_user_dir("Gen3", "cache")
#' credentials <- file.path(cache, "credentials.json")
#' if (file.exists(credentials))
#'     authenticate(credentials)
#'
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
