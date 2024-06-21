
library(shiny)
library(rmarkdown)
library(shinyWidgets)
library(shinyhttr)
library(tidyverse)


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
      "Your report is ready! Press 'Download Report'."
    }
  })
  
  output$download <- downloadHandler(
    # filename = "Reprod_ex.docx",
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