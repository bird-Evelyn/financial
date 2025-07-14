data <- read.csv("D:/桌面/Financial/all_a_stock_kline_data.csv")
markets <- unique(data$market)
for(mkt in markets){
  data_filtered <- data %>% 
    filter(market == mkt)
  write.csv(data_filtered, paste0(mkt,".csv"), row.names = F)
  cat("saved:", mkt, '\n')
}
