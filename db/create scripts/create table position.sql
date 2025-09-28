-- chess.`position` definition

CREATE TABLE `position` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `fen` varchar(100) NOT NULL,
  `move_white` varchar(10) DEFAULT NULL,
  `move_black` varchar(10) DEFAULT NULL,
  `half_move_num` int(10) unsigned NOT NULL,
  `game_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `position_game_id_IDX` (`game_id`) USING BTREE,
  CONSTRAINT `position_game_FK` FOREIGN KEY (`game_id`) REFERENCES `game` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=754068181 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
