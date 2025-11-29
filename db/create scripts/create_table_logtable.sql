-- chess.logtable definition

CREATE TABLE `logtable` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `dat` datetime NOT NULL DEFAULT current_timestamp(),
  `msg` varchar(2000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=Aria AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CHECKSUM=1 PAGE_CHECKSUM=1 TRANSACTIONAL=1;