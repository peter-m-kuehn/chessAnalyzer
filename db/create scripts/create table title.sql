-- chess.title definition

CREATE TABLE `title` (
  `title` varchar(100) NOT NULL,
  `title_date` date NOT NULL,
  `player_id` bigint(20) NOT NULL,
  UNIQUE KEY `title_unique` (`title_date`,`player_id`),
  KEY `title_player_id_IDX` (`player_id`) USING BTREE,
  CONSTRAINT `title_player_FK` FOREIGN KEY (`player_id`) REFERENCES `player` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;