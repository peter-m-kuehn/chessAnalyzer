import sys
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

engine_path = "c:/portable/stockfish/stockfish-windows-x86-64-sse41-popcnt.exe"

engine = chess.engine.SimpleEngine.popen_uci(engine_path)
engine.configure({"Threads": num_threads, "Hash": hash_mb})
search_limit = chess.engine.Limit()
search_limit.depth = max_depth
search_limit.time = movetime_sec

# The position represented in FEN
board = chess.Board("rnb1k2r/1p1n1pp1/p3p2p/2b5/2qNN3/2P1Q1B1/6PP/3RK2R w Kkq - 0 19", chess960=False)
print(board)

# Limit our search so it doesn't run forever
info = engine.analyse(board, limit=search_limit)
# get score and wdl
eng_score = info.get("score")
if eng_score is not None:
    centipawn = eng_score.white().score(
        mate_score=mate_centipawns
    )

    # get wdl
    wdl = eng_score.wdl()  # win/draw/loss info point of view is stm
    wins, draws, losses = (
        wdl[0],
        wdl[1],
        wdl[2],
    )
    print()
    print("centipawn: ", centipawn)
    print("wins: ", wins)
    print("draws: ", draws)
    print("losses: ", losses)

engine.quit()
sys.exit()

