
library(shiny)
library(rmarkdown)
library(shinyWidgets)
library(shinyhttr)
library(tidyverse)

ui <- fluidPage(
  
  titlePanel("Reproducable Example"),
  
  sidebarLayout(
    sidebarPanel(
      textInput(inputId = "username", label = "User name:"),
      tags$hr(),
      selectInput(inputId = "rtype", 
                  label = "Select a report:", 
                  choices = c("Falls" = "falls_test.rmd",
                              "Skin breakdown" = "3_skin_breakdown.rmd",
                              "Choking, Aspiration, Pneumonia" = "2_choking_aspiration_pneumonia.rmd",
                              "Agency All Events" = "4_agencies.rmd",
                              "Agency Falls" = "5_agencies_falls.rmd")),
      conditionalPanel(
        "input.rtype.includes('falls_test.rmd')",
        fileInput("files", HTML("Select files: <br/> 1. Census <br/> 2. Current year <br/> 3. Previous year"),
                  multiple = TRUE),
        # fileInput("current falls", "Select the current file:",
        #           multiple = TRUE),
        # fileInput("previous falls", "Select the previous file:",
        #           multiple = TRUE),
        numericInput("year", "Report year:", value = Sys.Date() |> str_sub(1, 4)),
        selectInput(inputId = 'month',
                    label = "Select a date range:",
                    choices = c('Q1' = "01, 02, 03",
                                'Q2' = "04, 05, 06",
                                'Q3' = "07, 08, 09",
                                'Q4' = "10, 11, 12",
                                'Annual' = 'NA'))
      ),
      conditionalPanel(
        "input.rtype.includes('2_choking_aspiration_pneumonia.rmd')",
        fileInput("census", "Select the census file:"),
        fileInput("current falls", "Select the current file:"),
        fileInput("previous falls", "Select the previous file:"),
        numericInput("year", "Report year:", value = Sys.Date() |> str_sub(1, 4)),
        selectInput(inputId = 'month',
                    label = "Select a date range:",
                    choices = c('Q1' = "01, 02, 03",
                                'Q2' = "04, 05, 06",
                                'Q3' = "07, 08, 09",
                                'Q4' = "10, 11, 12",
                                'Annual' = 'NA'))
      ),
      br(),
      downloadButton(outputId = "report", label = "Generate Report:"),
      tags$hr(),
      progressBar(
        id = "pb",
        value = 0,
        title = "",
        display_pct = TRUE
      )
    ),
    mainPanel(
      "some text",
      reactable::reactableOutput('table')
    )
  )
)


server <- function(input, output, session) {
  output$report <- downloadHandler(
    filename = "Reprod_ex.docx",
    content = function(file) {
      
      rmarkdown::render(input$rtype, 
                        output_format = NULL, 
                        params = list(census_path = input$files$datapath[1],
                                      current_falls_path = input$files$datapath[2],
                                      previous_falls_path = input$files$datapath[3],
                                      other_path = NA,
                                      year = input$year,
                                      month = input$month),
                        #params = list(username = input$username),
                        output_file = file
                        )
      
    }
  )
  output$table <- reactable::renderReactable({ 
    
    table <- tibble(datapath = input$files$datapath,
                    input = input$files$name)
    reactable::reactable(table)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)