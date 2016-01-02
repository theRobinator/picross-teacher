import array

import json

from picross.models.board import Board


def board_to_json(board):
    board_width = board.get_width()
    board_height = board.get_height()
    
    top_hints = []
    for i in xrange(board_width):
        top_hints.append(list(board.get_column_hints(i)))
        
    side_hints = []
    for i in xrange(board_height):
        side_hints.append(list(board.get_row_hints(i)))
    
    rows = []
    for i in xrange(board_height):
        this_row = []
        for j in xrange(board_width):
            this_row.append({'marking': board.get_mark(j, i)})
        rows.append(this_row)
    
    return json.dumps({
        'topHints': top_hints,
        'sideHints': side_hints,
        'rows': rows
    })


def json_to_board(json_str):
    try:
        json_obj = json.loads(json_str)
    except ValueError, e:
        print 'Failed to load board: Invalid json string %s' % json_str
        return None
    if 'topHints' not in json_obj or 'sideHints' not in json_obj or 'rows' not in json_obj:
        print 'Failed to load board: Missing properties in json object %s' % json_obj
        return None
    
    top_hints = json_obj['topHints']
    side_hints = json_obj['sideHints']
    rows = json_obj['rows']
    if type(top_hints) != list or type(side_hints) != list or type(rows) != list:
        print 'Failed to load board: non-list types in json object %s' % json_obj
        return None
    
    board_width = len(top_hints)
    board_height = len(side_hints)
    if board_width * board_height == 0:
        print 'Failed to load board: zero-length hints in json object %s' % json_obj
        return None
    
    board = Board(board_width, board_height)
    
    # Convert all hints to arrays for speed
    for hint_list in [top_hints, side_hints]:
        for i in xrange(len(hint_list)):
            hint_list[i] = array.array('i', hint_list[i])
            
    board.set_hints(top_hints, side_hints)
    for row_index in xrange(len(rows)):
        row = rows[row_index]
        if type(row) != list or len(row) != board_width:
            print 'Failed to load board: invalid row in json object %s' % json_obj
            return None
        for x in xrange(board_width):
            if 'marking' not in row[x]:
                print 'Failed to load board: Invalid cell in json object %s' % json_obj
            marking = row[x]['marking']
            if not 0 <= marking <= 2:
                print 'Failed to load board: invalid cell marking in json object %s' % json_obj
                return None
            board.mark_cell(x, row_index, marking)
    return board


def moves_to_json(moves):
    result = []
    for move in moves:
        result.append({
            'x': move.x,
            'y': move.y,
            'marking': move.marking,
            'name': move.name,
            'description': move.description
        })
    return json.dumps(result)
