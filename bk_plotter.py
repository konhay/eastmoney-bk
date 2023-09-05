import datetime
from dateutil.relativedelta import relativedelta

def plot_bk_overlay(ts_code, bk_code, display=False):
    """
    绘制近一年个股板块叠加图
    数据表:
        stock_daily_data tushare个股日线行情表
        east_bk_stock 东方财富板块个股成分表
        east_bk_daily 东方财富板块日线表
    """
    trade_date = datetime.date.today() + relativedelta(years=-1)

    sql = """select t1.trade_date, t1.close, t3.total_mv  
          FROM stock_daily_data t1 
              inner join east_bk_stock t2 
              inner join east_bk_daily t3 
          on t2.bk_code = t3.bk_code 
              and t1.trade_date = t3.trade_date 
              and t3.bk_code = t2.bk_code 
          where t1.ts_code = %s 
              and t1.trade_date > %s 
              and t2.stock_code = %s 
              and t2.bk_code = %s 
          order by t3.trade_date asc; """

    args = [ts_code, trade_date, ts_code[:-3], bk_code]
    df = mysql_util.get_mysql_client().df_read_mysql(sql, args)

    if not df.empty:
        fig, ax1 = plt.subplots(figsize=(10, 2.5))
        ax1.plot(range(len(df)), list(df['total_mv']), linestyle='-',
                 color='lightblue') #lightcoral/lightblue/red
        ax1.set_ylabel("total_mv")
        ax2 = ax1.twinx()
        ax2.plot(range(len(df)), list(df['close']))
        ax2.set_ylabel("close")
        fig.legend([bk_code, ts_code], loc='upper right')
        if display:
            plt.show()
        else:
            # dir = "savefig/" + ts_code
            # if not os.path.exists(dir): os.makedirs(dir)
            timestamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S%f')
            plt.savefig('savefig/' + timestamp + '.jpg')
            print("figure saved.")
        plt.close()
    else:
        print("dataframe is empty")


def plot_index_overlay(bk_code, display=False):
    """
    绘制近一年板块大盘叠加图
    数据表:
        index_daily_data tushare指数日线行情表
        east_bk_daily 东方财富板块日线表
    """
    trade_date = datetime.date.today() + relativedelta(years=-1)
    index_code = '000001.SH' #上证指数

    sql = """ select t1.trade_date, t1.close, t2.total_mv 
          from (SELECT trade_date, close FROM finance.index_daily_data 
              where ts_code = %s  and trade_date > %s ) t1 
          inner join (SELECT trade_date, total_mv FROM finance.east_bk_daily 
              where bk_code = %s and trade_date > %s ) t2 
          on t1.trade_date = t2.trade_date order by t1.trade_date asc; """

    args =[index_code, trade_date, bk_code, trade_date]
    df = mysql_util.get_mysql_client().df_read_mysql(sql, args)

    if not df.empty:
        fig, ax1 = plt.subplots(figsize=(10, 2.5))
        ax1.plot(range(len(df)), list(df['close']), linestyle='-',
                 color='lightblue') #lightcoral/lightblue/red
        ax1.set_ylabel("close")
        ax2 = ax1.twinx()
        ax2.plot(range(len(df)), list(df['total_mv']))
        ax2.set_ylabel("total_mv")
        fig.legend([index_code, bk_code], loc='upper right')
        if display:
            plt.show()
        else:
            # dir = "savefig/" + bk_code
            # if not os.path.exists(dir): os.makedirs(dir)
            timestamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S%f')
            plt.savefig('savefig/' + timestamp + '.jpg')
            print("figure saved.")
        plt.close()
    else:
        print("dataframe is empty")
