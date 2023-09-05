CREATE DEFINER=`root`@`localhost` PROCEDURE `finance`.`getBkDailyPro`(
    in _bk_code varchar(6), 
	in _trade_date varchar(8)
  )
begin
	/* 输入
	 * _bk_code 东财板块代码
	 * _trade_date 交易日期
	 * 
	 * 返回查询结果
	 * pct_chg_wt 板块按个股权重计算的涨跌幅
	 * pct_chg_mv 基于板块总市值变动计算的涨跌幅
	 * pct_chg_ix 当日指数涨跌幅
	*/
	
    -- select your bk
    -- SELECT bk_code, bk_name, count(0) as ct FROM finance.east_bk_stock where date = '2020-08-10' group by bk_code, bk_name
    -- order by ct;
    
	-- get stock list for bk (filter those not in ts basic)
    drop table if exists bk_stock_list;
    create temporary table bk_stock_list
    select bk_code, bk_name, ts_code, stock_name from
    (select bk_code, bk_name, stock_code, stock_name  from east_bk_stock where bk_code = _bk_code) t1
    inner join
    (select ts_code, substr(ts_code, 1, 6) as stock_code from stock_basic_data) t2
    on t1.stock_code = t2.stock_code;
    
    -- include total mv
    drop table if exists stock_daily_mv;
    create temporary table stock_daily_mv
    select bk_code, bk_name, t1.ts_code, stock_name, trade_date, round(total_mv/10000, 2) as total_mv from
    bk_stock_list t1 inner join 
    (select ts_code, trade_date, total_mv from stock_daily_basic where trade_date > _trade_date) t2
    on t1.ts_code = t2.ts_code ;

    -- get bk daily mv
    drop table if exists bk_daily_mv;
      create temporary table bk_daily_mv
      select a.* , @rownum:=@rownum+1 as rownum
    from (
     select t1.bk_code, t1.bk_name, trade_date, round(sum(total_mv), 2) as total_mv from
    bk_stock_list t1 inner join stock_daily_mv t2
    on t1.ts_code = t2.ts_code
    group by t1.bk_code, t1.bk_name, trade_date
    order by trade_date asc
    ) a,  (SELECT @rownum:=0) t;

    -- compute bk weights
    drop table if exists bk_weights;
      create temporary table bk_weights
    select t1.bk_code, t1.bk_name, t1.ts_code, t1.stock_name, t1.trade_date
    , t1.total_mv as stock_mv, t2.total_mv as bk_mv, round(t1.total_mv/t2.total_mv, 3) as weight from
    stock_daily_mv t1 inner join bk_daily_mv t2
    on t1.bk_code = t2.bk_code and t1.trade_date = t2.trade_date;

    -- check weight sum
    -- select bk_code, bk_name, trade_date, sum(weight) from bk_weights group by trade_date, bk_code, bk_name;

    -- weighted sum(%)
    drop table if exists weighted_sum;
      create temporary table weighted_sum
    select bk_code, bk_name, t1.trade_date
    , round(sum(pct_chg*weight), 2) as pct_chg
    from bk_weights t1 inner join stock_daily_data t2
    on t1.ts_code = t2.ts_code and t1.trade_date = t2.trade_date
    group by bk_code, bk_name, trade_date;

    -- copy bk daily mv 
    drop table if exists bk_daily_mv_2;
      create temporary table bk_daily_mv_2
      select * from bk_daily_mv;

    -- bk mv change(%, better)
    drop table if exists mv_change;
      create temporary table mv_change
    select t1.bk_code, t1.bk_name, t1.trade_date, t1.total_mv, t2.trade_date as last_date, t2.total_mv as last_mv
    , round((t1.total_mv/t2.total_mv-1)*100, 2) as pct_chg from bk_daily_mv t1
    inner join bk_daily_mv_2 t2
    on t1.rownum = t2.rownum+1 and t1.bk_code = t2.bk_code;

 -- combine result(wt/mv/index)
	select t3.*, t4.pct_chg as pct_chg_ix from 
    (select t1.trade_date
    , t1.pct_chg as pct_chg_wt
    , t2.pct_chg as pct_chg_mv 
    from weighted_sum t1 inner join mv_change t2
	on t1.bk_code = t2.bk_code and t1.trade_date = t2.trade_date) t3 
     inner join (select * from index_daily_data where ts_code = '000001.SH') t4
     on t3.trade_date = t4.trade_date
    order by trade_date asc;

	-- drop tmp tables
    drop table bk_stock_list;
    drop table stock_daily_mv;
    drop table bk_daily_mv;
    drop table bk_weights;
    drop table weighted_sum;
    drop table bk_daily_mv_2;
    drop table mv_change;
END;
