#' Defunct functions
#'
#' @description
#' `r lifecycle::badge("defunct")`
#'
#' These functions were deprecated for at least five release cycles before being
#' made defunct. If there's a known replacement, calling the function
#' will tell you about it.
#'
#' @keywords internal
#' @name defunct
NULL

#' @usage # Deprecated in 0.3.* -------------------------------------
#' @name defunct
NULL

#' @noRd
#' @rdname defunct
ifcb_get_svea_position <- function(...) {
  lifecycle::deprecate_stop("0.3.4", "ifcb_get_svea_position()", "iRfcb::ifcb_get_ferrybox_data()")
}
