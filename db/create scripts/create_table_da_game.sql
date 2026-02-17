-- chess.da_game definition

CREATE TABLE `da_game` (
  `game_id` bigint(20) NOT NULL,
  `acpl_white` double DEFAULT NULL,
  `acpl_black` double DEFAULT NULL,
  `stdcpl_white` double DEFAULT NULL,
  `stdcpl_black` double DEFAULT NULL,
  `accuracy_avg_white` double DEFAULT NULL,
  `accuracy_avg_black` double DEFAULT NULL,
  `sum_engine_moves_white` int(10) unsigned DEFAULT NULL,
  `sum_engine_moves_black` int(10) unsigned DEFAULT NULL,
  `sum_normal_moves_white` int(10) unsigned DEFAULT NULL,
  `sum_normal_moves_black` int(10) unsigned DEFAULT NULL,
  `sum_mistake_moves_white` int(10) unsigned DEFAULT NULL,
  `sum_mistake_moves_black` int(10) unsigned DEFAULT NULL,
  `sum_blunder_moves_white` int(10) unsigned DEFAULT NULL,
  `sum_blunder_moves_black` int(10) unsigned DEFAULT NULL,
  `game_length` int(10) unsigned DEFAULT NULL,
  `sum_inaccurate_moves_white` int(10) unsigned DEFAULT NULL,
  `sum_inaccurate_moves_black` int(10) unsigned DEFAULT NULL,
  KEY `da_game_game_id_IDX` (`game_id`) USING BTREE,
  CONSTRAINT `da_game_game_FK` FOREIGN KEY (`game_id`) REFERENCES `game` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;