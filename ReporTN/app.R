
library(shiny)
library(rmarkdown)
library(shinyWidgets)
library(shinyhttr)
library(tidyverse)

r_title_date <- tibble(
  inp = c("01, 02, 03", "04, 05, 06", "07, 08, 09", "10, 11, 12", 'NA'),
  text = c("Quarterly", "Quarterly", "Quarterly", "Quarterly", ""),
  date = c(" - First Quarter", " - Second Quarter", " - Third Quarter", " - Fourth Quarter", " - Annual")
)

r_title_rtype <- tibble(
  inp = c(
    "1_falls.rmd", 
    "2_choking_aspiration_pneumonia.rmd", 
    "3_skin_breakdown.rmd", 
    "4_agencies.rmd", 
    "5_agencies_falls.rmd"),
  text = c(
    "Falls",
    "Choking Aspiration Pneumonia",
    "Skin Breakdown",
    "Agency All Events",
    "Agency Falls"
  )
)

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
      #reactable::reactableOutput('table2'),
      textOutput('text')
    )
  )
)


server <- function(input, output, session) {
  
  # IMPORTANT!
  # this is needed to terminate the R process when the
  # shiny app session ends. Otherwise, you end up with a zombie process
  session$onSessionEnded(function() {
    stopApp()
  })
  
  reactives <- reactiveValues(
    params_list = list(),
    filepath = NULL,
    filename = ""
  )
  
  observe({
    if (input$rtype == "1_falls.rmd") {
      reactives$params_list <- list(census_path = input$files_1$datapath[1],
                                    current_falls_path = input$files_1$datapath[2],
                                    previous_falls_path = input$files_1$datapath[3],
                                    other_path = NA,
                                    year = input$year_1,
                                    month = input$month_1)
      
      reactives$filename <- paste0(
        r_title_date |> filter(inp == input$month_1) |> pull(text), " ",
        r_title_rtype |> filter(inp == input$rtype) |> pull(text), " Report",
        r_title_date |> filter(inp == input$month_1) |> pull(date)
        )
      
    } else if (input$rtype == "2_choking_aspiration_pneumonia.rmd") {
      reactives$params_list <- list(census_path = input$files_2$datapath[1],
                                    cho_path = input$files_2$datapath[2],
                                    current_asp_path = input$files_2$datapath[3],
                                    past_asp_path = input$files_2$datapath[4],
                                    year = input$year_2,
                                    month = input$month_2)
      
      reactives$filename <- paste0(
        r_title_date |> filter(inp == input$month_2) |> pull(text), " ",
        r_title_rtype |> filter(inp == input$rtype) |> pull(text), " Report",
        r_title_date |> filter(inp == input$month_2) |> pull(date)
      )
      
    } else if (input$rtype == "3_skin_breakdown.rmd") {
      reactives$params_list <- list(census_path = input$files_3$datapath[1],
                                    ski_path = input$files_3$datapath[2],
                                    year = input$year_3,
                                    month = input$month_3)
      
      reactives$filename <- paste0(
        r_title_date |> filter(inp == input$month_3) |> pull(text), " ",
        r_title_rtype |> filter(inp == input$rtype) |> pull(text), " Report",
        r_title_date |> filter(inp == input$month_3) |> pull(date)
      )
      
    } else if (input$rtype == "4_agencies.rmd") {
      reactives$params_list <- list(census_path = input$files_4$datapath[1],
                                    cho_path = input$files_4$datapath[2],
                                    asp_path = input$files_4$datapath[3],
                                    ski_path = input$files_4$datapath[4],
                                    falls_path = input$files_4$datapath[5],
                                    year = input$year_4)
      
      reactives$filename <- paste0(
        " ",
        r_title_rtype |> filter(inp == input$rtype) |> pull(text), 
        " Report - Annual"
      )
      
    } else if (input$rtype == "5_agencies_falls.rmd") {
      reactives$params_list <- list(census_path = input$files_5$datapath[1],
                                    falls_path = input$files_5$datapath[2],
                                    year = input$year_5)
      
      reactives$filename <- paste0(
        " ",
        r_title_rtype |> filter(inp == input$rtype) |> pull(text), 
        " Report - Annual"
      )
      
    }
  })
  
  observeEvent(input$go, {
    tmp_file <- paste0(tempfile(), ".docx")
    
    withProgress(message = "Setting the tables...", {
      rmarkdown::render(
        input$rtype, 
        output_format = "all", 
        params = append(reactives$params_list, list(rendered_by_shiny = TRUE)),
        output_file = tmp_file,
        envir = new.env(parent = globalenv())
      )
    })
    
    reactives$filepath <- tmp_file
  })
  
  output$text <- renderText({
    if (!is.null(reactives$filepath) == FALSE) {
      "Please wait for progress to complete."
    } else {
      HTML("Your report is ready! Press 'Download Report'.")
    }
  })
  
  output$download <- downloadHandler(
    
    filename = function() {
      paste0(
        Sys.Date() |> str_sub(1, 4), 
        " ",
        reactives$filename,
        ".docx"
        ) 
    },
    
    content = function(file) {
      file.copy(reactives$filepath, file)
    }
  )
  
  # for troubleshooting
  # output$table <- reactable::renderReactable({ 
  #   
  #   table <- tibble(datapath = input$files$datapath,
  #                   input = input$files$name)
  #   reactable::reactable(table)
  #   })
  # 
  # output$table2 <- reactable::renderReactable({ 
  #   
  #   table <- tibble(values = reactives$params_list)
  #   reactable::reactable(table)
  # })
  # 
}

# Run the application 
shinyApp(ui = ui, server = server)