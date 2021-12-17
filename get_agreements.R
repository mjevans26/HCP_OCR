library(dplyr)
library(httr)
library(rvest)
library(ecosscraper)
TECP_table <- get_TECP_table()
spp_agmt <- data.frame(Type = character(0), Plan = character(0), Link = character(0), Spp = character(0))
for(i in 1:nrow(TECP_table)){
  url <- TECP_table$Species_Page[i]
  species <- TECP_table$Scientific_Name[i]
  page <- read_html(url)
  tables <- try(html_nodes(page, "table"))
  if(length(grep("(CCAA Plan)", tables)) > 0){
    CCAA_table <- tables[grep("(CCAA)", tables)]
    CCAAs <- html_table(CCAA_table)[[1]][1][,1]
    CCAA_links <- html_nodes(CCAA_table, "a")
    CCAA_df <- data.frame(Type = rep("CCAA", length(CCAAs)), 
                          Plan = CCAAs,
                          Link = html_attr(CCAA_links, "href"),
                          Spp = rep(species, length(CCAAs)))
    spp_agmt <- rbind(spp_agmt, CCAA_df)
  }
  if(length(grep("(CCA Plan)", tables)) > 0){
    CCA_table <- tables[grep("(CCA )", tables)]
    CCAs <- html_table(CCA_table)[[1]][1][,1]
    CCA_links <- html_nodes(CCA_table, "a")
    CCA_df <- data.frame(Type = rep("CCA", length(CCAs)), 
                         Plan = CCAs,
                         Link = html_attr(CCA_links, "href"),
                         Spp = rep(species, length(CCAs)))
    spp_agmt <- rbind(spp_agmt, CCA_df)
  }
  if(length(grep("(HCP Plan)", tables)) > 0){
    HCP_table <- tables[grep("(HCP Plan)", tables)]
    HCPs <- html_table(HCP_table)[[1]][1][,1]
    HCP_links <- html_nodes(HCP_table, "a")
    HCP_df <- data.frame(Type = rep("HCP", length(HCPs)), 
                         Plan = HCPs,
                         Link = html_attr(HCP_links, "href"),
                         Spp = rep(species, length(HCPs)))
    spp_agmt <- rbind(spp_agmt, HCP_df)
  }
  if(length(grep("(SHA Plan)", tables)) > 0){
    SHA_table <- tables[grep("(SHA)", tables)]
    SHAs <- html_table(SHA_table)[[1]][1][,1]
    SHA_links <- html_nodes(SHA_table, "a")
    SHA_df <- data.frame(Type = rep("SHA", length(SHAs)), 
                         Plan = SHAs,
                         Link = html_attr(SHA_links, "href"),
                         Spp = rep(species, length(SHAs)))
    spp_agmt <- rbind(spp_agmt, SHA_df)
  }
  rm(tables)
}
spp_agmt$ScrapeDate <- Sys.Date()

plans_spp <- group_by(spp_agmt, Link)%>%
  summarise(Plan = first(Plan), Type = first(Type))


plans_from_spp <- data.frame()
for(i in 1:nrow(plans)){
  url <- paste("https://ecos.fws.gov", plans$Link[i], sep="")
  page <- read_html(url)
  tab <- ecosscraper::get_conservation_plan_data(url, "")
  plans_from_spp <- bind_rows(plans_from_spp, as.data.frame(tab))
}

get_conservation_plan_links <- function(types, method = "spp")
page_agmt <- data.frame(Type = character(0), Plan = character(0), Link = character(0)) 
for(i in c("HCP", "SHA", "CCA", "CCAA")){
  url <- paste("https://ecos.fws.gov/ecp0/conservationPlan/region?region=9&type=", i, sep = "")
  page <- read_html(url)
  opt_nodes <- html_nodes(page, "option")
  ids <- html_attr(opt_nodes, "value")
  names <- html_text(opt_nodes)
  links <- paste("https://ecos.fws.gov/ecp0/conservationPlan/plan?plan_id=", ids, sep = "")
  type <- i
  df <- data.frame(Type = type, Plan = names, Link = links)
  page_agmt <- bind_rows(page_agmt, df)
  rm(df)
}

test <- group_by(page_agmt, Link)%>%
  summarise(Plan = first(Plan), Type = first(Type))
  
page_not_spp <- plans_page[!plans_page$Link %in% plans_spp$Link, ]
spp_not_page <- plans_spp[!plans_spp$Link %in% plans_page$Link, ]

plans_from_pages <- data.frame()
for(i in 1:nrow(page_not_spp)){
  url <- page_not_spp$Link[i]
  page <- read_html(url)
  tab <- ecosscraper::get_conservation_plan_data(url, "")
  plans_from_pages <- bind_rows(plans_from_pages, as.data.frame(tab))
}

diff <- function(m1, m2){
  d <- m1 - m2
  z <- (d - mean(d))/sd(d)
  p <- pnorm(abs(z), lower.tail = FALSE)
  return(list("d" = d, "z" = z, "p" = p))
}

weights <-  function(d, p){
    d2 <- p*d
    z2 <- (d2 - mean(d2))/sd(d2)
    p2 <- pnorm(abs(z2), lower.tail = FALSE)
    return(list("d" = d2, "z" = z2, "p" = p2))
}

for (i in 1:10){
  di <- get(paste("dif", i, sep = ""))
  dif <- weights(dif$p, di$d, di$z)
}
  

plans_all$Type <- vapply(1:nrow(plans_all), function(i){
  type <- links_spp$Type[links_spp$Plan == plans_all$Plan_Name[i]]
  if (length(type) == 0) {type <- links_page$Type[links_page$Plan == plans_all$Plan_Name[i]]}
  if (length(type) == 0) {type <- ("")}
  return(type)},
  USE.NAMES = FALSE, FUN.VALUE = character(1))

