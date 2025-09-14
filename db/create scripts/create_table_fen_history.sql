CREATE TABLE `fen_history` (
	`game_date` DATE NOT NULL,
	`fen_pos` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	INDEX `fen_history_compound_i` (`fen_pos`, `game_date`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;
