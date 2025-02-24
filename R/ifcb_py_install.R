#' Install iRfcb Python Environment
#'
#' This function creates and activates a Python virtual environment named "iRfcb" and installs the required Python packages as specified in the "requirements.txt" file.
#' Additional packages can be installed by passing them through the `packages` argument.
#'
#' @param ... Additional arguments passed to `virtualenv_create`, such as `packages`.
#' @param envname A character string specifying the name of the virtual environment to create. Default is "~/.virtualenvs/iRfcb".
#'
#' @examples
#' \dontrun{
#' # Install the iRfcb Python environment
#' ifcb_py_install()
#'
#' # Install the iRfcb Python environment with additional packages
#' ifcb_py_install(packages = c("numpy", "pandas"))
#' }
#' @export
ifcb_py_install <- function(..., envname = ".virtualenvs/iRfcb") {
  args <- list(...)

  if ("packages" %in% names(args)) {
    virtualenv_create(envname, requirements = system.file("python", "requirements.txt", package = "iRfcb"), packages = args$packages)
  } else {
    virtualenv_create(envname, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
  }

  use_virtualenv(envname)
}
