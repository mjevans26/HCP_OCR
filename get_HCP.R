library(dplyr)
library(httr)
library(rvest)

df <- read.csv(file = 'data/FWS_Species_Data_Explorer_HCPs.csv', header = TRUE, stringsAsFactors = FALSE)
base <- 'https://ecos.fws.gov'

# out_df <- data.frame('file' = c(), 'id' = c(), 'title' = c())
for(i in 1:nrow(df)){
  id <- df[i,7]
  title <- df[i,8]
  suffix <- df[i,9]
  url <- paste(base, suffix, sep = '')
  
  page <- read_html(url)
  links <- html_nodes(page, 'a')
  pdfs <- links[grep('.pdf', links)]
  files <- html_attr(pdfs, 'href')
  
  if(length(pdfs) == 0){
    row <- data.frame('file' = NA, 'id' = id, 'title' = title)
  }else{
    row <- data.frame('file' = files, 'id' = id, 'title' = title)
  }
  
  if(i == 1){
    out_df <- row
  }else{
    out_df <- bind_rows(out_df, row)
  }
  
}

write.csv(out_df, file = 'data/HCP_docs_8Jun21.csv')
