.GEN3_DOWNLOAD_URL <- "https://gen3.theanvil.io/user/data/download"

.download_object_id_as_gs <-
    function(object_id)
{
    url0 <- paste0(.GEN3_DOWNLOAD_URL, "/", object_id)
    response <- GET(url0)
    stop_for_status(response)

    url1 <- content(response)$url
    sub("https://storage.googleapis.com/(.*)\\?.*", "gs://\\1", url1)
}

#' @rdname download
#'
#' @title Access and download objects from Gen3 google buckets
#'
#' @description `download_stat()` returns information about objects
#'     available for download from Gen3.
#'
#' @param object_id character(1) object identifier returned from a
#'     query of form `values("sequences", "object_id", ...)`.
#'
#' @details These functions must be run in the AnVIL environment, or
#'     with `gcloud` command line tools available and configured to
#'     such that `AnVIL::gcloud_project()` returns a billing account
#'     (e.g., belonging to AnVIL) that will allow 'requester pays'
#'     downloads.
#'
#'     `download_stat()` fails if the object is not available,
#'     the user does not have permission to access the object, or the
#'     user does not have billing enabled.
#'
#' @return `download_stat()` returns an object of class
#'     `gcloud_sdk_result`, which when printed displays statistics on
#'     the object.
#'
#' @examples
#' ## object_id of smallest object at time of writing; see vignette
#' object_id <- "dg.ANV0/76050167-ff6a-445d-9376-c3d9192fd02b"
#'
#' \dontrun{
#' ## Who will pay for the downloads?
#' AnVIL::gcloud_project()
#'
#' download_stat(object_id)
#' }
#'
#' @importFrom AnVIL gsutil_stat
#'
#' @export
download_stat <-
    function(object_id)
{
    stopifnot(
        .is_object_id(object_id)
    )

    gs <- .download_object_id_as_gs(object_id)
    gsutil_stat(gs)
}

#' @rdname download
#'
#' @description `download_object()` retieves the object id to a local
#'     file system or another google bucket for which the user has
#'     write access.
#'
#' @param destination character(1) location to retrieve the file,
#'     either a local path or a 'gs://' uri with appropriate write
#'     permissions, e.g., as returned by `AnVIL::avbucket()` in AnVIL.
#'
#' @return `download_object()` returns the path or bucket in which the
#'     object was stored.
#'
#' @examples
#' \dontrun{
#' destination <- download_object(object_id, tempfile())
#' file.info(destination) %>% as_tibble()
#'
#' destination <- download_object(object_id, AnVIL::avbucket())
#' destination
#' AnVIL::avfiles_stat(destination)
#' }
#' @importFrom AnVIL gsutil_cp
#'
#' @export
download_object <-
    function(object_id, destination)
{
    stopifnot(
        .is_object_id(object_id),
        .is_scalar_character(destination)
    )
    is_dir <- dir.exists(destination)
    is_gs_uri <- AnVIL:::.gsutil_is_uri(destination)
    stopifnot(
        `'destination' exists as a local file` =
            is_gs_uri || is_dir  || !file.exists(destination)
    )

    gs <- .download_object_id_as_gs(object_id)
    filename <- basename(gs)

    if (is_dir) {
        path <- file.path(destination, filename)
        if (file.exists(path))
            stop(
                "'destination' directory contains a file '",
                filename,
                "' that would be over-written by downloading"
            )
    }

    if (is_gs_uri) {
        is_gs_object <- tryCatch({
            gsutil_stat(paste0(destination, "/", filename))
            TRUE
        }, error = function(...) FALSE)
        stopifnot(`'destination' exists as a gs object` = !is_gs_object)
    }

    response <- gsutil_cp(gs, destination)

    if (is_dir || is_gs_uri)
        destination <- file.path(destination, filename)

    destination
}
