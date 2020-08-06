.is_scalar <-
    function(x)
{
    length(x) == 1L && !is.na(x)
}

.is_scalar_character <-
    function(x)
{
    is.character(x) && .is_scalar(x)
}

.is_scalar_numeric <-
    function(x)
{
    is.numeric(x) && .is_scalar(x)
}

.tibbilize_list <-
    function(lst)
{
    if (is(lst, "data.frame")) {
        lst <- as_tibble(lst)
    } else if (is(lst, "list")) {
        lst <- lapply(lst, .tibbilize_list)
    }
    lst
}
