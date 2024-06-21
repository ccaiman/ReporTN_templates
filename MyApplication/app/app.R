pandoc <- file.path(getwd(), "dist/pandoc-3.2")
Sys.setenv(PATH = pandoc)

# app launching code, e.g.:
shiny::runApp("./app/shiny/", launch.browser=TRUE)
