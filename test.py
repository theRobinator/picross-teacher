import pyximportcpp; pyximportcpp.install(inplace=True)
#import pyximport; pyximport.install(inplace=True)

from os import path
from sys import argv

from picross.io import textio

from picross.models import cellmarking

from picross.solvers.bruteforce import BruteForce
from picross.solvers.finalspaces import FinalSpaces
from picross.solvers.forcing import Forcing
from picross.solvers.multisolver import MultiSolver
from picross.solvers.simpleboxes import SimpleBoxes


if len(argv) > 1:
    if not argv[1].endswith('.txt'):
        argv[1] += '.txt'
    board = textio.puzzle_from_hint_file(path.join('testpuzzles', argv[1]))
else:
    board = textio.puzzle_from_hint_file(path.join('testpuzzles', '15x15_puppy.txt'))

solver = MultiSolver([
    FinalSpaces(),
    SimpleBoxes(),
    BruteForce()
])

while True:
    print board
    moves = solver.get_next_moves(board)
    if len(moves) == 0:
        break
        
    last_name = moves[0].name
    for move in moves:
        if move.name != last_name:
            last_name = move.name
            print board, "\n"
        board.mark_cell(move.x, move.y, move.marking)
        print move

for y in xrange(board.get_height()):
    line = []
    for x in xrange(board.get_width()):
        marking = board.get_mark(x, y)
        if marking == cellmarking.BLACK:
            line.append('\033[42m   \033[0m')
        else:
            line.append('   ')
    print ''.join(line)
