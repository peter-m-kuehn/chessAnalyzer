-- chess.elo definition

CREATE TABLE `elo` (
  `elo_num` int(10) unsigned NOT NULL,
  `elo_date` date NOT NULL,
  `player_id` bigint(20) NOT NULL,
  UNIQUE KEY `elo_unique` (`elo_date`,`player_id`),
  KEY `elo_player_id_IDX` (`player_id`) USING BTREE,
  CONSTRAINT `elo_player_FK` FOREIGN KEY (`player_id`) REFERENCES `player` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;