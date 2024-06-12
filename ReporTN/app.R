
library(shiny)
library(rmarkdown)
library(shinyWidgets)
library(shinyhttr)
library(tidyverse)

ui <- fluidPage(
  
  titlePanel("Reproduceable Example"),
  
  sidebarLayout(
    sidebarPanel(
      textInput(inputId = "username", label = "User name:"),
      tags$hr(),
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
        fileInput("files", HTML("Select files: <br/> 1. Census <br/> 2. Current year"),
                  multiple = TRUE),
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
        "input.rtype.includes('4_agencies.rmd')",
        fileInput("files", HTML("Select files: <br/> 1. Census <br/> 2. Current choking <br/> 3. Current aspiration <br/> 4. Current skin <br/> 5. Current falls"),
                  multiple = TRUE),
        numericInput("year", "Report year:", value = Sys.Date() |> str_sub(1, 4))
      ),
      conditionalPanel(
        "input.rtype.includes('5_agencies_falls.rmd')",
        fileInput("files", HTML("Select files: <br/> 1. Census <br/> 2. Current falls"),
                  multiple = TRUE),
        numericInput("year", "Report year:", value = Sys.Date() |> str_sub(1, 4))
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
      reactable::reactableOutput('table2'),
      textOutput('text')
    )
  )
)


server <- function(input, output, session) {
  
  reactives <- reactiveValues(
    params_list = list()
  )
  
  observe({
    if (input$rtype == "1_falls.rmd") {
      reactives$params_list <- list(census_path = input$files_1$datapath[1],
                                    current_falls_path = input$files_1$datapath[2],
                                    previous_falls_path = input$files_1$datapath[3],
                                    other_path = NA,
                                    year = input$year_1,
                                    month = input$month_1)
    } else if (input$rtype == "2_choking_aspiration_pneumonia.rmd") {
      reactives$params_list <- list(census_path = input$files_2$datapath[1],
                                    cho_path = input$files_2$datapath[2],
                                    current_asp_path = input$files_2$datapath[3],
                                    past_asp_path = input$files_2$datapath[4],
                                    year = input$year_2,
                                    month = input$month_2)
    }
  })
  
  output$report <- downloadHandler(
    filename = "Reprod_ex.docx",
    content = function(file) {
      
      rmarkdown::render(input$rtype, 
                        output_format = NULL, 
                        params = reactives$params_list,
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
  
  output$table2 <- reactable::renderReactable({ 
    
    table <- tibble(values = reactives$params_list)
    reactable::reactable(table)
  })
  
  output$text <- renderText({
    input$rtype
  })
}



# Run the application 
shinyApp(ui = ui, server = server)