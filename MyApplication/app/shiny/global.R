GLOBAL_VAR = "loaded from global.R"

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
