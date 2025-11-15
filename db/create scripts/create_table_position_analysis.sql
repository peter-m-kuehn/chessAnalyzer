-- chess.position_analysis definition

CREATE TABLE `position_analysis` (
  `position_id` bigint(20) NOT NULL,
  `centipawn` int(11) NOT NULL,
  `wins` int(11) NOT NULL,
  `draws` int(11) NOT NULL,
  `losses` int(11) NOT NULL,
  `best_move_uci` varchar(10) NOT NULL,
  `depth` int(11) NOT NULL,
  `seldepth` int(11) NOT NULL,
  `nodes` int(11) NOT NULL,
  `time_sec` float NOT NULL,
  KEY `position_analysis_position_FK` (`position_id`),
  CONSTRAINT `position_analysis_position_FK` FOREIGN KEY (`position_id`) REFERENCES `position` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;