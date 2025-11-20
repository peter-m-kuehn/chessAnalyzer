import argparse
import getpass
import sys
import logging
import chessdb as db
from dataclasses import dataclass
import chess
import chess.engine

# performance tuning parameters
num_threads = 20
hash_mb = 48000

# analysis limits
max_depth = 30
movetime_sec = 15
num_moves_to_return = 1
mate_centipawns = 32000

engine_path = "c:/portable/stockfish/stockfish-windows-x86-64-avx2.exe"
# configure chess engine
engine = chess.engine.SimpleEngine.popen_uci(engine_path)
engine.configure({"Threads": num_threads, "Hash": hash_mb})
search_limit = chess.engine.Limit(depth=max_depth, time=movetime_sec)


def analyze_position(p_fen, p_pos_id):
    board = chess.Board(p_fen, chess960=False)
    if board.is_checkmate() or board.is_stalemate():
        logging.info(f"Position {p_pos_id} is terminal, skipping analysis.")
        return None # no analysis for terminal positions     
    position_analysis = db.PositionAnalysisRecord()
    position_analysis.position_id = p_pos_id
    stm = board.turn
    info = engine.analyse(board, search_limit)
    logging.info(f"Analyzed position: {info}")
    position_analysis.best_move_uci = info["pv"][0].uci()
    position_analysis.depth = info["depth"]
    position_analysis.seldepth = info["seldepth"]
    position_analysis.nodes = info["nodes"]
    position_analysis.time_sec = info["time"]

    # get score and wdl
    eng_score = info.get("score")
    if eng_score is not None:
        position_analysis.centipawn = eng_score.white().score(
            mate_score=mate_centipawns
        )

        # get wdl
        wdl = eng_score.wdl()  # win/draw/loss info point of view is stm
        position_analysis.wins, position_analysis.draws, position_analysis.losses = (
            wdl[0],
            wdl[1],
            wdl[2],
        )

    return position_analysis


def analyse_game(p_game_id):
    try:
        # make sure analysis does not already exist
        if db.position_analysis_exists(p_game_id):
            logging.info(f"Game {p_game_id} already analyzed, skipping.")
            return

        logging.info(f"Start analyzing game {p_game_id}.")
        for position_row in db.get_positions(p_game_id):
            pos_id = position_row[0]
            fen = position_row[1]
            position_analysis = analyze_position(fen, pos_id)
            if position_analysis is not None:   
                db.insert_position_analysis(position_analysis)

        db.commit()
        logging.info(f"Finished analyzing game {p_game_id}.")
    except Exception as e:
        logging.error(f"Error analyzing game {p_game_id}: {e}")
        db.rollback


def main():
    # use basic logging
    logging.basicConfig(
        filename="logs.log",
        level=logging.INFO,
        format="%(asctime)s %(levelname)-8s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        filemode="w",
    )

    # get command line arguments IDplayer and password
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--IdPlayer",
        type=int,
        required=True,
        help="player ID from chess database",
    )
    parser.add_argument(
        "-p",
        "--password",
        type=str,
        required=True,
        default='',
        nargs='?',
        help="database password for chess_user",
    )
    args = parser.parse_args()
    # If password not provided, prompt securely
    if not args.password:
        try:
            args.password = getpass.getpass(prompt="Enter database password: ")
        except (KeyboardInterrupt, EOFError):
            print("\nPassword input cancelled.")
            sys.exit(1)

    # Validate password input
    if not args.password.strip():
        print("Error: Database password cannot be empty.")
        sys.exit(1)

    # connect to database
    try:
        db.connect(args.password)

        # main loop: get games for player and analyze each
        for row in db.get_games(args.IdPlayer):
            analyse_game(row[0])

        db.rollback()
        db.disconnect()
        engine.quit()
    except Exception as e:
        logging.error(f"Fatal error: {e}")
        try:
            db.disconnect()
        except:
            pass
        engine.quit()
        sys.exit(1)


if __name__ == "__main__":
    main()
