-- finance.east_bk_info definition

CREATE TABLE `east_bk_info` (
  `bk_source` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `bk_type` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `bk_code` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `bk_name` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `url` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `use_flag` int DEFAULT NULL,
  PRIMARY KEY (`bk_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='东方财富板块信息';