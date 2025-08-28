-- chess.player definition

CREATE TABLE `player` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `fide_id` bigint(20) DEFAULT NULL,
  `name` varchar(300) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `player_name_uk` (`name`),
  KEY `player_fide_id_IDX` (`fide_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=103322 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;