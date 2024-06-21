
library(shiny)
library(rmarkdown)
library(shinyWidgets)
library(shinyhttr)
library(tidyverse)

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  br(),
  img(src = "tn_dda_logo.png", height = "75px"),
  div(
    class = 'quote',
    HTML('<strong>Mission: </strong><i>To become the nation’s most person-centered and cost-effective\
         state support system for people with intellectual and developmental disabilities.</i>')
  ),
  div(
    class = 'quote',
    HTML('<strong>Vision: </strong><i>Support all Tennesseans with intellectual and\
         developmental disabilities to live the lives they envision for themselves.</i>')
  ),
  
  titlePanel("ReporTN templates"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(inputId = "rtype", 
                  label = "Select a report:", 
                  choices = c("Falls" = "1_falls.rmd",
                              "Choking, Aspiration, Pneumonia" = "2_choking_aspiration_pneumonia.rmd",
                              "Skin breakdown" = "3_skin_breakdown.rmd",
                              "Agency All Events" = "4_agencies.rmd",
                              "Agency Falls" = "5_agencies_falls.rmd")),
      conditionalPanel(
        "input.rtype.includes('1_falls.rmd')",
        fileInput("files_1", HTML("Select files: <br/> 1. Census <br/> 2. Current year <br/> 3. Previous year"),
                  multiple = TRUE),
        numericInput("year_1", "Report year:", value = Sys.Date() |> str_sub(1, 4)),
        selectInput(inputId = 'month_1',
                    label = "Select a date range:",
                    choices = c('Q1' = "01, 02, 03",
                                'Q2' = "04, 05, 06",
                                'Q3' = "07, 08, 09",
                                'Q4' = "10, 11, 12",
                                'Annual' = 'NA'))
      ),
      conditionalPanel(
        "input.rtype.includes('2_choking_aspiration_pneumonia.rmd')",
        fileInput("files_2", HTML("Select files: <br/> 1. Census <br/> 2. Choking: current year <br/> 3. Aspiration: current year <br/> 4. Aspiration: previous year"),
                  multiple = TRUE),
        numericInput("year_2", "Report year:", value = Sys.Date() |> str_sub(1, 4)),
        selectInput(inputId = 'month_2',
                    label = "Select a date range:",
                    choices = c('Q1' = "01, 02, 03",
                                'Q2' = "04, 05, 06",
                                'Q3' = "07, 08, 09",
                                'Q4' = "10, 11, 12",
                                'Annual' = 'NA'))
      ),
      conditionalPanel(
        "input.rtype.includes('3_skin_breakdown.rmd')",
        fileInput("files_3", HTML("Select files: <br/> 1. Census <br/> 2. Current year"),
                  multiple = TRUE),
        numericInput("year_3", "Report year:", value = Sys.Date() |> str_sub(1, 4)),
        selectInput(inputId = 'month_3',
                    label = "Select a date range:",
                    choices = c('Q1' = "01, 02, 03",
                                'Q2' = "04, 05, 06",
                                'Q3' = "07, 08, 09",
                                'Q4' = "10, 11, 12",
                                'Annual' = 'NA'))
      ),
      conditionalPanel(
        "input.rtype.includes('4_agencies.rmd')",
        fileInput("files_4", HTML("Select files: <br/> 1. Census <br/> 2. Current choking <br/> 3. Current aspiration <br/> 4. Current skin <br/> 5. Current falls"),
                  multiple = TRUE),
        numericInput("year_4", "Report year:", value = Sys.Date() |> str_sub(1, 4))
      ),
      conditionalPanel(
        "input.rtype.includes('5_agencies_falls.rmd')",
        fileInput("files_5", HTML("Select files: <br/> 1. Census <br/> 2. Current falls"),
                  multiple = TRUE),
        numericInput("year_5", "Report year:", value = Sys.Date() |> str_sub(1, 4))
      ),
      tags$hr(),
      actionButton(inputId = "go", label = "Generate Report"),
      br(),
      br(),
      conditionalPanel(
        condition = "",
        downloadButton(outputId = "download", label = "Download Report")
      ),
    ),
    mainPanel(
      tags$html(
        tags$body(
          p("This is a reporting tool to generate our standard reports on reportable events.\
      The templates contain tables of descriptive and diagnostic statistics for the team to interpret and report."),
          hr(),
          "The sidepanel walks you through the steps to generate a report.",
          br(),
          HTML("<ul>\
                  <li>\
                    At the 'Select files:' step, please rename the files so they have a leading value (like 1_, 1-, or 1.) according to the numbered list.\
                    Select each of the files you need, then press 'Open'.\
                    The selection order doesn't matter but the leading numeric value in the file name does.\
                  </li>\
                  <li>\
                    When everything looks right, press 'Generate Report'.\
                    A progress bar will pop up in the lower-right corner.\
                    A successful download will be a '.docx' file.\
                    If there was a problem, the download is an empty '.html' file.\
                  </li>\
                </ul>")
        )
      ),
      br(),
      #reactable::reactableOutput('table2'),
      textOutput('text')
    )
  )
)