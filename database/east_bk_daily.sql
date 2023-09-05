-- finance.east_bk_daily definition

CREATE TABLE `east_bk_daily` (
  `bk_code` varchar(6) NOT NULL COMMENT '板块代码',
  `bk_name` varchar(10) DEFAULT NULL COMMENT '板块名称',
  `trade_date` varchar(8) NOT NULL COMMENT '交易日期',
  `total_mv` float DEFAULT NULL COMMENT '总市值（亿元）',
  `pct_chg` float DEFAULT NULL COMMENT '日涨跌幅',
  PRIMARY KEY (`bk_code`,`trade_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COMMENT='基于总市值的板块日涨跌幅度表';