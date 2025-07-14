data_zb <- read.csv("主板.csv")

# 检查是否有缺失数据
any(is.na(data_zb))

# 判断是否达到涨停，每日涨跌
data_zb <- data_zb %>% 
  mutate(trade_date_num = as.numeric(trade_date)) %>% 
  arrange(name, trade_date_num) %>%   
  group_by(name) %>%  
  mutate(  
    up_end = ifelse(high >= round(pre_close * 1.1, 2), TRUE, FALSE),
    up_or_down = ifelse(open >= close, TRUE, FALSE)
  ) %>%  
  ungroup()  

# 筛选(条件1:收盘价&振幅)
data_zb_choose1 <- data_zb %>% 
  group_by(name) %>% 
  summarise(
    max_high = max(high),
    min_low = min(low),
    close_on_today = close[trade_date == 20250626],
    .drop = TRUE
  ) %>% 
  filter(
    close_on_today <= 0.5 * max_high,
    max_high >= 3 * min_low
  )
name_lim <- unique(data_zb_choose1$name)
data_zb_choose1 <-  data_zb %>% 
  filter(name %in% name_lim)

# 筛选(条件2:涨停板成交量)
# 具体的筛选逻辑：计算第一次涨停点前五个交易日的平均成交量为average_vol
# 然后再从涨停点向后搜寻，看是否有成交量的值处于[0.9*average_vol,1.1*average_vol]之间，
# 注意这里面可能涨停点前面没有满足五天的数据，这时可以利用小于五天的全部数据
# 若一个数据都没有，可以利用涨停板当天的数据。
analyze_stock <- function(stock_df){
  first_up_end <- which(stock_df$up_end == TRUE)[1]
  
  if(is.na(first_up_end)){
    return(NULL)
  }
  
  pre_indices <- max(1, first_up_end - 5):(first_up_end - 1)
  
  if(length(pre_indices) == 0){
    average_vol <- stock_df$vol[first_up_end]
  }
  else{
    average_vol <- mean(stock_df$vol[pre_indices], na.rm = TRUE)
  }
  
  lower_bound <- 0.9 * average_vol
  upper_bound <- 1.1 * average_vol
  
  # for(i in (first_up_end + 1):nrow(stock_df)){
  #   vol_i <- stock_df$vol[i]
  #   if(all(!is.na(vol_i)) && all(vol_i >= lower_bound & vol_i <= upper_bound)){
  #     return(stock_df$name[1])
  #   }
  #}
  
  for(i in (first_up_end + 1):(nrow(stock_df) - 2)){
    vols <- stock_df$vol[i:(i+2)]
    if(all(!is.na(vols)) && all(vols >= lower_bound & vols <= upper_bound)){
      return(stock_df$name[1])
    }
  }
  return(NULL)
}

data_zb_choose2 <- data_zb_choose1 %>% 
  group_by(name) %>% 
  group_split() %>% 
  lapply(analyze_stock) 
  

selected_stocks <- unique(unlist(data_zb_choose2))
print(selected_stocks)
