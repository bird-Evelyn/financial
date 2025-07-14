# 参数设置
# 计算第一次涨停点跃过k[1]交易日后连续k[2]交易日的平均成交量为average_vol
# 然后用今日的前k[3]个交易日，看成交量的值是否都处于[k[4]*average_vol,k[5]*average_vol]之间
k <- c(5, 2, 4, 0.9, 1.1)


# 主代码
library(tidyverse)
data_zb <- read_csv("主板.csv")

# 检查是否有缺失数据
any(is.na(data_zb))

# 判断是否达到涨停，每日涨跌
data_zb <- data_zb %>% 
  mutate(  
    up_end = ifelse(high >= round(pre_close * 1.1, 2), TRUE, FALSE),
    up_or_down = ifelse(open >= close, TRUE, FALSE)
  )

# 筛选(条件1:收盘价&振幅)
data_zb_choose1 <- data_zb %>% 
  group_by(name) %>% 
  summarise(
    # 计算半年来的最大值（不是收盘的最大值，是整个的）
    max_high = max(high),
    # 计算半年来的最小值（不是收盘的最小值，是整个的）
    min_low = min(low),
    # 计算今天的收盘价格
    close_on_today = close[trade_date == 20250626],
    .groups = "drop"
  ) %>% 
  filter(
    # 今日收盘价不到半年来最高价的一半
    close_on_today <= 0.5 * max_high,
    # 半年来最高价曾是最低价的三倍及以上
    max_high >= 3 * min_low
  )
name_lim <- unique(data_zb_choose1$name)
write_csv(data_zb_choose1, file = "Chosen1.csv")
data_zb_choose1 <-  data_zb %>% 
  filter(name %in% name_lim)
write_csv(data_zb_choose1, file = "k_line_chosen1")

# 筛选(条件2:涨停板成交量)
# 具体的筛选逻辑：计算第一次涨停点跃过k[1]交易日后连续k[2]交易日的平均成交量为average_vol
# 然后用今日的前k[3]个交易日，看成交量的值是否都处于[0.9*average_vol,1.1*average_vol]之间
analyze_stock <- function(stock_df, k) {
  first_up_end <- which(stock_df$up_end == TRUE)[1]
  name <- stock_df$name[1]  # 提取股票名
  
  # 情况1：没有出现涨停
  if (is.na(first_up_end)) {
    return(data.frame(name = name, result = "No limit up."))
  }
  
  # 情况2：涨停太靠近今天
  if (first_up_end - k[3] <= 0) {
    return(data.frame(name = name, result = "The time of last limit up is too close to today."))
  }
  
  # 情况3：涨停时间太远，数据不够
  if (first_up_end + k[1] + k[2] > nrow(stock_df)) {
    return(data.frame(name = name, result = "The time of last limit up is too far from today."))
  }
  
  # 计算区间
  pre_indices <- (first_up_end + k[1] + 1):(first_up_end + k[1] + k[2])
  average_vol <- mean(stock_df$vol[pre_indices], na.rm = TRUE)
  lower_bound <- k[4] * average_vol
  upper_bound <- k[5] * average_vol
  
  vols <- stock_df$vol[1:k[3]]
  
  # 检查是否在波动范围内
  if (all(!is.na(vols)) && all(vols >= lower_bound & vols <= upper_bound)) {
    return(data.frame(name = name, result = "pass"))
  } else {
    return(data.frame(name = name, result = "Out of range."))
  }
}


data_zb_choose2 <- data_zb_choose1 %>% 
  group_by(name) %>% 
  group_split() %>% 
  lapply(function(df) analyze_stock(df, k)) %>%
  bind_rows()

View(data_zb_choose2)

