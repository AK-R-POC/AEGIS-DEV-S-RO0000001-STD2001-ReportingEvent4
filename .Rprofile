source("renv/activate.R")
renv_activate <- file.path(getwd(), "renv", "activate.R")
profile_here <- file.path(getwd(), ".Rprofile")

if (file.exists(renv_activate) && file.exists(profile_here)) {
  source(renv_activate)
} else {
  message("[INFO] renv/activate.R not found or .Rprofile not found; skipping activation for now.")
  return(invisible(NULL))
}

# Recommended パッケージがユーザライブラリのみにある場合、自動で renv library に入れる
message("[INFO] Install Recommended packages.")
repos <- getOption("repos")
message("[INFO] Current repositories:")
for (i in seq_along(repos)) {
  message(sprintf("  %s = %s", names(repos)[i], repos[i]))
}

local({
  recommended_pkgs <- c(
    "MASS", "boot", "Matrix", "lattice", "nlme", "survival",
    "mgcv", "class", "cluster", "codetools", "foreign",
    "KernSmooth", "nnet", "rpart", "spatial"
  )
  
  proj_lib <- renv::paths$library()
  
  # renv library にまだ入っていないものを検出
  missing <- recommended_pkgs[
    !file.exists(file.path(proj_lib, recommended_pkgs, "DESCRIPTION"))
  ]
  
  if (length(missing) > 0 && interactive()) {
    message("Installing recommended packages from INHOUSE: ",
            paste(missing, collapse = ", "))
    try(renv::install(missing, prompt = FALSE))
  }
})
message("[INFO] Initialization completed.")
