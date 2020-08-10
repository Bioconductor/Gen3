.TERRA_ANVIL_ACCESSTOKEN <-
    "https://broad-bond-prod.appspot.com/api/link/v1/anvil/accesstoken"
.GEN3_CREDENTIALS <-
    "https://gen3.theanvil.io/user/credentials/cdis/access_token"

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

#' @importFrom AnVIL gcloud_cmd
#'
#' @importFrom httr add_headers GET POST stop_for_status content
#'
#' @importFrom jsonlite fromJSON
.authenticate_gcloud_terra <-
    function()
{
    gcloud_token <- gcloud_cmd("auth", "print-access-token")
    header <- add_headers(Authorization=paste("Bearer", gcloud_token))
    response <- GET(.TERRA_ANVIL_ACCESSTOKEN, header)
    stop_for_status(response)
    content(response)$token
}

.authenticate_credentials <-
    function(credentials_file)
{
    stopifnot(file.exists(credentials_file))

    gen3token <- fromJSON(credentials_file)
    response <- POST(.GEN3_CREDENTIALS, body=gen3token, encode="json")
    stop_for_status(response)
    content(response, encoding = "UTF-8")$access_token
}

#' @rdname authenticate
#'
#' @title Authenticate against gen3.theanvil.io
#'
#' @description Authenticate against gen3.theanvil.io using
#'     credentials obtained external to _R_. Authentication persis for
#'     the duration of the _R_ session, or until authentication
#'     expires using criteria defined on the server.
#'
#' @param file character(1) or NULL. If character(1), file path to
#'     json credentials, as described in the 'details' section.
#'
#' @details To obtain credentials for direct access to Gen3, visit
#'     https://gen3.theanvil.io, login, and click on the profile
#'     icon. There you can create an access credential as a JSON
#'     file. Download this file and remember its location. Do not
#'     share this file with others. A convenient location to store
#'     the credentials file is at this location:
#'
#'         cache <- tools::R_user_dir("Gen3", "cache")
#'         credentials <- file.path(cache, "credentials.json")
#'
#'     To use with an AnVIL account, log in to
#'     https://anvil.terra.bio, select the 'Profile' item on the
#'     'HAMBURGER' dropdown, and use 'NHGRI AnVIL Data Commons
#'     Framework Services' to link AnVIL with your Gen3 account. When
#'     on the AnVIL platform, or with the `gcloud` binary on your
#'     search path and with `AnVIL::gcloud_cmd("auth", "list")`
#'     incidating the correct account for AnVIL access, gain access to
#'     Gen3 with no arguments, `authenticate()`.
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
#' @export
authenticate <-
    function(file = NULL)
{
    if (is.null(file)) {
        token <- .authenticate_gcloud_terra()
    } else {
        token <- .authenticate_credentials(file)
    }

    value <- .BEARER_TOKEN(token)
    invisible(value)
}        
