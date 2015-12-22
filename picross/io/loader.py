import re

from picross.models.board import Board
from picross.models import cellmarking


def puzzle_from_string(puzzle_string):
    """ Create a Board object from a puzzle string displaying a picture. For each line, a space is empty and any other
    character is filled.
    :param puzzle_string:
    :return:
    """
    lines = puzzle_string.split("\n")
    size = len(lines[0])
    if size != len(lines):
        raise Exception('Puzzles must be squares (found %d x %d puzzle)' % (size, len(lines)))

    board = Board(size, size)
    for h in xrange(size):
        for w in xrange(size):
            if lines[h][w] == ' ':
                board.set_answer(w, h, cellmarking.WHITE)
            else:
                board.set_answer(w, h, cellmarking.BLACK)

    board.refresh_hints()

    return board


def puzzle_from_hints(hint_string):
    """ Create a Board object from a file containing only hints, in the form
    col1_hint col1_hint col1_hint
    col2_hint col2_hint col2_hint
    
    row1_hint row1_hint row1_hint
    row2_hint row2_hint row2_hint
    
    :param hint_string: 
    :return: 
    """
    lines = hint_string.split("\n")
    top_hints = []
    side_hints = []
    current_hints = top_hints
    for line in lines:
        line = line.strip()
        if line == '':
            if current_hints is top_hints:
                current_hints = side_hints
                continue
            else:
                raise Exception('Only one blank line can be specified in a hint file')
        
        numbers = re.split("\s+", line)
        current_hints.append([int(i) for i in numbers])
    
    width = len(top_hints)
    height = len(side_hints)
    if width == 0 or height == 0:
        raise Exception('Both top and side hints must be specified to make a puzzle (Got %d x %d). Use a blank line to separate top and side hints.' % (width, height))

    board = Board(width, height)
    board.set_hints(top_hints, side_hints)
    return board


def puzzle_from_puzzle_file(filename):
    if filename.endswith('.txt'):
        with open(filename, 'r') as fp:
            return puzzle_from_string(fp.read())
    else:
        raise Exception('Only txt files can be read from')


def puzzle_from_hint_file(filename):
    if filename.endswith('.txt'):
        with open(filename, 'r') as fp:
            return puzzle_from_hints(fp.read())
    else:
        raise Exception('Only txt files can be read from')
