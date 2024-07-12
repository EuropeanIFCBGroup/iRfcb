#' Install iRfcb Python Environment
#'
#' This function creates and activates a Python virtual environment named "iRfcb" and installs the required Python packages as specified in the "requirements.txt" file.
#'
#' @param ... Additional arguments passed to `virtualenv_create`.
#' @param envname A character string specifying the name of the virtual environment to create. Default is "iRfcb".
#'
#' @examples
#' \dontrun{
#' # Install the iRfcb Python environment
#' ifcb_py_install()
#' }
#' @importFrom reticulate virtualenv_create use_virtualenv
#' @export
ifcb_py_install <- function(..., envname = "/.virtualenvs/iRfcb") {
  virtualenv_create(envname, requirements = system.file("python", "requirements.txt", package = "iRfcb"))

  use_virtualenv(envname)
}
