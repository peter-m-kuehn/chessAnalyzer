CREATE TABLE `fen_history` (
  `game_date` date NOT NULL,
  `fen_pos` varchar(100) NOT NULL,
  UNIQUE KEY `fen_history_fen_pos_IDX` (`fen_pos`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
