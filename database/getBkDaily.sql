CREATE DEFINER=`root`@`localhost` PROCEDURE `finance`.`getBkDaily`(
    in _bk_code varchar(6), 
	in _trade_date varchar(8)
  )
BEGIN
	/* 输入
	 * _bk_code 东财板块代码
	 * _trade_date 交易日期
	 * 
	 * 插入east_bk_daily
	 * total_mv 板块总市值
	 * pct_chg 基于板块总市值变动计算的涨跌幅
	*/
	IF _trade_date is NULL THEN 
		SET _trade_date = (select max(trade_date) from east_bk_daily where bk_code = _bk_code);
	END IF;
        
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
    select bk_code, bk_name, t1.ts_code, trade_date, round(total_mv/10000, 2) as total_mv from
    bk_stock_list t1 inner join 
    (select ts_code, trade_date, total_mv from stock_daily_basic where trade_date >= _trade_date) t2
    on t1.ts_code = t2.ts_code ;

    -- get bk daily mv
    drop table if exists bk_daily_mv;
      create temporary table bk_daily_mv
      select a.* , @rownum:=@rownum+1 as rownum
    from (
     select bk_code, bk_name, trade_date, round(sum(total_mv), 2) as total_mv 
     from stock_daily_mv t2
    group by bk_code, bk_name, trade_date
    order by trade_date asc
    ) a,  (SELECT @rownum:=0) t;

    -- copy bk daily mv 
    drop table if exists bk_daily_mv_2;
      create temporary table bk_daily_mv_2
      select * from bk_daily_mv;

    -- bk mv change(%, better)
    insert into east_bk_daily
    select t1.bk_code, t1.bk_name, t1.trade_date, t1.total_mv
    , round((t1.total_mv/t2.total_mv-1)*100, 2) as pct_chg from bk_daily_mv t1
    inner join bk_daily_mv_2 t2
    on t1.rownum = t2.rownum+1 and t1.bk_code = t2.bk_code;
    
    commit;

	-- drop tmp tables
    drop table bk_stock_list;
    drop table stock_daily_mv;
    drop table bk_daily_mv;
    drop table bk_daily_mv_2;
    
END;
