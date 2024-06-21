pandoc <- file.path(getwd(), "dist/", list.files(path = "dist", pattern = "pandoc")[1])

Sys.setenv(PATH = pandoc)

# app launching code, e.g.:
shiny::runApp("./app/shiny/", launch.browser=TRUE)
