import tushare as ts
import pandas as pd
import time
import logging
from datetime import datetime, timedelta

# 1. 设定时间范围
end_date = datetime(2025, 6, 26)
start_date = datetime(2025, 6, 20)
start_str = start_date.strftime('%Y-%m-%d')
end_str = end_date.strftime('%Y-%m-%d')

# 2. 配置日志模块
logging.basicConfig(
    filename='download_log.log',
    filemode='a',  # 追加写入
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S'
)

# 3. 初始化tushare pro接口
pro = ts.pro_api('2876ea85cb005fb5fa17c809a98174f2d5aae8b1f830110a5ead6211')

# 4. 获取所有A股信息：代码/特定交易所股票的股票代码/名称/地域/行业类别/上市的交易所/首次在上市交易所的日期
stock_df = pro.stock_basic(exchange='', list_status='L',
                           fields='ts_code,symbol,name,area,industry,market,list_date')
logging.info(f"共获取 {len(stock_df)} 支股票")


# 检查是否成功
if stock_df.empty or 'ts_code' not in stock_df.columns:
    logging.error("获取股票列表失败，stock_df为空或缺少 ts_code")
    print("获取股票列表失败，stock_df为空或缺少 ts_code")
    exit(1)

print("股票列表示例：")
print(stock_df.head())
print("列名：", stock_df.columns)


all_data = []

# 5. 获取某一只股票的日K线数
# #TODO：max_retries=3, retry_delay=5意味着获取数据失败时最多重试3次，每次重试之间等待5秒
def fetch_data_with_retry(ts_code, max_retries=3, retry_delay=5):
    attempt = 0
    while attempt < max_retries:
        try:
            df = pro.daily(ts_code=ts_code, start_date=start_str,end_date=end_date)
            if df.empty:
                logging.warning(f"{ts_code} 无数据")
            else:
                logging.info(f"{ts_code} 下载成功，记录数：{len(df)}")
            return df
        except Exception as e:
            attempt += 1
            logging.error(f"{ts_code} 下载失败，尝试第 {attempt} 次，错误：{e}")
            time.sleep(retry_delay)
    logging.error(f"{ts_code} 下载失败，超过最大重试次数，跳过。")
    return pd.DataFrame()

# 6. 遍历每一只股票，获取日K线数据，合并保存数据
for i, ts_code in enumerate(stock_df['ts_code']):
    df = fetch_data_with_retry(ts_code)
    if not df.empty:
        df['ts_code'] = ts_code
        all_data.append(df)
    time.sleep(1.2)  # 限流延迟

if all_data:
    df_all = pd.concat(all_data, ignore_index=True)
    df_all = df_all.merge(stock_df[['ts_code', 'name', 'market']], on='ts_code', how='left')
    df_all.to_csv('all_a_stock_kline_data.csv', index=False, encoding='utf-8-sig')
    logging.info("数据已保存到 all_a_stock_kline_data.csv")
else:
    logging.warning("没有成功获取任何数据。")
