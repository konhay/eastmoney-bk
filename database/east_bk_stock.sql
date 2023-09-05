-- finance.east_bk_stock definition

CREATE TABLE `east_bk_stock` (
  `bk_code` varchar(6) NOT NULL COMMENT '板块代码',
  `bk_name` varchar(10) DEFAULT NULL COMMENT '板块名称',
  `bk_type` varchar(10) DEFAULT NULL,
  `stock_code` varchar(6) NOT NULL COMMENT '个股代码',
  `stock_name` varchar(10) DEFAULT NULL COMMENT '个股名称',
  `update_date` date DEFAULT NULL COMMENT ' 更新日期',
  PRIMARY KEY (`bk_code`,`stock_code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COMMENT='东方财富板块个股成分信息';
