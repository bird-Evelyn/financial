1.股票数据是从tushare上下载的，然后对应python代码data(1).py

2.数据各个变量的实际含义

ts_code：股票代码 （str） ；    trade_date：交易日期 （str）；

open : 开盘价（float)  ;                high：最高价 ；

low : 最低价  ；                             close：收盘价

pre_close ：昨收价（前复权）；change：涨跌额

pct_chg  ：涨跌幅（未复权）  ；vol：成交量（手）

amount ：成交额（千元）；      name：股票名称

up_end ：代表股票今日是否达到涨停板，是为TRUE，否为FALSE

up_or_down：代表股票今日的涨跌情况，TRUE为涨，FALSE为跌

3.classify.r文件中代码是将数据按照所在板块划分出来

4.choose.r文件中代码进行股票的筛选

5.choose.r中代码中的限定条件为以下三个：

  （1）最高值和最低值相差300%，其中我设置的最高值是股票每日最高价的最高值，最低值是股票每日最低价的最低值

  （2）今日收盘价低于最高价的50%，这里的最高值依旧是股票每日最高价的最高值

  （3）计算第一次涨停点前面跳过k[1]交易日后，以k[1]交易日前面的连续k[2]交易日的平均成交量为average_vol。然后用今日为起点的前k[3]个交易日，看成交量的值是否都处于[k[4]*average_vol,k[5]*average_vol]之间。（k[1]，k[2],...,k[5]可自定义设值）
