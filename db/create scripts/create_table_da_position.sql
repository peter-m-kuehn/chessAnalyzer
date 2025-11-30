-- chess.da_position definition

CREATE TABLE `da_position` (
  `position_id` bigint(20) NOT NULL,
  `white_winning_chances` double DEFAULT NULL,
  `white_score_rate` double DEFAULT NULL,
  `white_draw_rate` double DEFAULT NULL,
  `black_winning_chances` double DEFAULT NULL,
  `black_score_rate` double DEFAULT NULL,
  `black_draw_rate` double DEFAULT NULL,
  `accuracy` double DEFAULT NULL,
  `judgement` varchar(100) DEFAULT NULL,
  `sharpness` double DEFAULT NULL,
  UNIQUE KEY `da_position_unique` (`position_id`),
  CONSTRAINT `da_position_position_FK` FOREIGN KEY (`position_id`) REFERENCES `position` (`id`),
  CONSTRAINT `judgement_check` CHECK (`judgement` in ('ENGINE','INACCURACY','MISTAKE','BLUNDER'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;