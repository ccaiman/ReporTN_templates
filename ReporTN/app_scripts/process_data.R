
import_event_data <- function(path_str, 
                              event_str = c("fall_events", 
                                            "choking_events", 
                                            "skin_events", 
                                            "aspiration_events", 
                                            "pneumonia_events")){
  
  path <- path_str
  event <- event_str
  
  #default sheet = 1
  #aspiration needs sheet = 3
  #pneumonia needs sheet = 2
  
  event_df <- tibble(
    event_str = c("fall_events", 
                  "choking_events", 
                  "skin_events", 
                  "aspiration_events", 
                  "pneumonia_events"),
    event_n = c(1,
                1,
                1,
                3,
                2)
  )
  
  data_ <- read_xlsx(path = path,
                          sheet = event_df |> filter(event_str == event) |> pull(event_n),
                          skip = 0,
                          col_names =  TRUE
  )
  
  titles <- read_xlsx(path = ".titles/event_titles.xlsx",
                           sheet = event,
                           skip = 0,
                           col_types = c("text", "text", "text", "text"))
  
  names <- titles$clean
  
  type <- titles$type
  
  
  if (length(names) < length(data_)) {
    extra_cols <- length(names) + 1
    names[extra_cols:length(data_)] <- "text"
    type[extra_cols:length(data_)] <- "text"
  } else {
    names <- names
    type <- type
  }
  
  data <- read_xlsx(path = path,
                         sheet = event_df |> filter(event_str == event) |> pull(event_n),
                         skip = 1,
                         col_names = names,
                         col_types = type)
  
  data <- data |> 
    filter(grepl('1915', program) | is.na(program)) |> 
    filter(!is.na(last_name))
  
  return(data)
}

collapse_names <- function(data_df){
  
  data <- data_df
  
  data$agency <- case_match(
    data$agency,
    data$agency[grep("Sevita Health", data$agency)] ~ "Sevita Health (aka D&S)",
    data$agency[grep("Support Solutions", data$agency)] ~ "Support Solutions",
    data$agency[grep("Sunrise", data$agency)] ~ "Sunrise",
    data$agency[grep("RHA", data$agency)] ~ "RHA",
    data$agency[grep("Evergreen", data$agency)] ~ "Evergreen",
    data$agency[grep("CG of TN", data$agency)] ~ "CG of TN",
    .default = data$agency
  )
  
  return(data)
}

change_names <- function(census_df){
  
  census <- census_df
  
  census$agency <- case_match(
    census$agency,
    census$agency[grep("Public Partnerships", census$agency)] ~ "Consumer Direct for TN",
    .default = census$agency)
  
  return(census)
}

quarterly_report_months <- function(data_df){
  
  data <- data_df
  
  inc_date <- as_tibble(str_split(data$event_date, pattern = "-", n = 3, simplify = T))
  
  data$inc_year <- inc_date$V1
  data$inc_mon <- inc_date$V2
  data$inc_day <- inc_date$V3
  
  if (month[1] == 'NA') {
    data_report <- data |>  
      filter(inc_year == year)
  } else {
    data_report <- data |>  
    filter(inc_year == year) |> 
    filter(inc_mon == month[1] | inc_mon == month[2] | inc_mon == month[3])
  }
  
  
  
  data_report$inc_mon_rep <- recode(data_report$inc_mon,
                                         "01" = paste("Jan. ", year),
                                         "02" = paste("Feb. ", year),
                                         "03" = paste("Mar. ", year),
                                         "04" = paste("Apr. ", year),
                                         "05" = paste("May. ", year),
                                         "06" = paste("Jun. ", year),
                                         "07" = paste("Jul. ", year),
                                         "08" = paste("Aug. ", year),
                                         "09" = paste("Sep. ", year),
                                         "10" = paste("Oct. ", year),
                                         "11" = paste("Nov. ", year),
                                         "12" = paste("Dec. ", year))
  
  data_report$inc_mon_num <- as.numeric(data_report$inc_mon)
  
  return(data_report)
}



census_key <- function(census_df){
  
  census <- census_df
  
  census <- census |> 
    filter(is.na(agency) == FALSE)
  
  agency_key <- census |> 
    distinct(agency) |> 
    mutate(agency_id = 1:length(agency))
  
  census <- left_join(census, agency_key)
  
  #use the input month to index the census table for the specified months
  if (month[1] == "NA") {
    census_mon <- census |> select(jan:dec)
    names(census_mon) <- c("m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "m12")
    
    
    census_mon <- census_mon |> 
      rowwise() |> 
      transmute(cen_mean = round(mean(`m1`:`m12`, na.rm = TRUE), 0))
  } else {
    census_mon1 <- as.numeric(month[1]) + 2
    census_mon3 <- as.numeric(month[3]) + 2
  
    census_mon <- census[,census_mon1:census_mon3]
    names(census_mon) <- c("m1", "m2", "m3")
    
    census_mon <- census_mon |> 
      rowwise() |> 
      transmute(cen_mean = round(mean(`m1`:`m3`, na.rm = TRUE), 0))
  }
  
  
  #add X1 and X2 (agency info) back to the table of specified months
  census_mon$agency <- census$agency
  census_mon$abrev <- census$abrev
  census_mon$agency_id <- census$agency_id
  
  #make abbreviations for each unique agency based on full name
  mast_census <- census_mon %>% select(!abrev)
  mast_census$abrev <- str_sub(mast_census$agency, 1, 4)
  
  #and then three letters
  abr_census <- census_mon %>% select(!agency)
  abr_census$abrev <- str_sub(abr_census$abrev, 1, 4)
  
  #the agencies that have two abbreviations
  alternate_names <- anti_join(abr_census, 
                               mast_census, 
                               by = join_by("abrev"))
  
  
  #the final census data has row entries for 3L abbreviations
  #of the long name or abbreviated name
  mast_census_comb <- bind_rows(mast_census, alternate_names) |> 
    select(!agency) |> 
    left_join(agency_key, by = join_by(agency_id))
  
  
  mast_census_comb_q <- mast_census_comb |> 
    select(agency_id, abrev, cen_mean)
  
  #then, the 3L abbreviation in the log can be matched to a 3L entry 
  #derived from the long or short name to add the census to the log data
  
  agency_key2 <- bind_rows(mast_census_comb_q, 
                           agency_key |> 
                             mutate(abrev = agency)) |> 
    select(!agency) |> 
    group_by(agency_id) |> 
    mutate(cen_mean = max(cen_mean, na.rm = TRUE))
  
  return(agency_key2)
}


match_key <- function(data_df, census_df){
  data_report <- data_df
  agency_key2 <- census_df
  
  #first pass (1) to match the agency info to the data:
  #match the agency name in the census to the name in the data
  data_report$abrev <- str_sub(data_report$agency, 1, 4)
  
  data_report_p1 <- left_join(data_report, 
                                   agency_key2 |> 
                                     rename(agency = abrev), 
                                   by = join_by("agency")) |> 
    select(agency, abrev, agency_id, cen_mean, c_id) |> 
    drop_na() #keep only the matches
  
  #we need another way to match the remaining agencies
  data_report_p1_na <- left_join(data_report, 
                                      agency_key2 |> 
                                        rename(agency = abrev), 
                                      by = join_by("agency")) |> 
    select(agency, abrev, agency_id, cen_mean, c_id) |> 
    filter(is.na(agency_id)) #keep the non matches
  
  #second pass (2) to match the agency info to the data:
  #match the agency abbreviation in the census to the abbreviation derived from the name in the data
  data_report_p2 <- left_join(data_report, 
                                   agency_key2, 
                                   by = join_by("abrev")) |> 
    select(agency, abrev, agency_id, cen_mean, c_id)
  
  #remove the rows that were also matched by full name (duplicate entries)
  data_report_p3 <- anti_join(data_report_p2, 
                                   data_report_p1,
                                   by = join_by(agency))
  
  #bind the rows matched by full name (p1) and the entries matched by abbreviation (p3)
  data_report_p4 <- bind_rows(data_report_p1,
                                   data_report_p3)
  
  #the rows are out of order, se we can use c_id to rematch with the original data frame
  data_report <- left_join(data_report |> 
                                  select(!c(agency, abrev)), 
                                data_report_p4,
                                by = join_by(c_id))
  
  return(data_report)
}


census_key_yearly <- function(census_df){
  census <- census_df

  census <- drop_na(census)
  
  agency_key <- census |> 
    distinct(agency) |> 
    mutate(agency_id = 1:length(agency))
  
  census <- left_join(census, agency_key)
  
  #make abbreviations for each unique agency based on full name
  mast_census <- census |> select(!abrev)
  mast_census$abrev <- str_sub(mast_census$agency, 1, 4)
  
  #and then three letters
  abr_census <- census |>  select(!agency)
  abr_census$abrev <- str_sub(abr_census$abrev, 1, 4)
  
  #the agencies that have two abbreviations
  alternate_names <- anti_join(abr_census, mast_census, by = join_by("abrev"))
  
  
  #the final census data has row entries for 3L abbreviations
  #of the long name or abbreviated name
  mast_census_comb <- bind_rows(mast_census, alternate_names)
  
  census_comb_mean <- mast_census_comb |> 
    group_by(agency_id) |> 
    slice(1) |> 
    mutate(cen_mean = round(sum(jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec)/12, 0)) |> 
    select(cen_mean, agency_id)
  
  mast_census_comb_q <- left_join(mast_census_comb, census_comb_mean, by = join_by("agency_id")) |> 
    select(agency_id, abrev, cen_mean)
  
  #then, the 3L abbreviation in the log can be matched to a 3L entry 
  #derived from the long or short name to add the census to the log data
  
  agency_key2 <- bind_rows(mast_census_comb_q, 
                           agency_key |> 
                             mutate(abrev = agency)) |> 
    select(!agency) |> 
    group_by(agency_id) |> 
    mutate(cen_mean = max(cen_mean, na.rm = TRUE))
  
  return(agency_key2)
}