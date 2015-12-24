#cython: wraparound=False

from picross.models.board cimport Board

from picross.models import cellmarking
from picross.models.move import Move


cdef class FinalSpaces(object):
    
    cpdef list get_next_moves(self, Board board):
        cdef list moves = [], row, column, possible_moves
        cdef int[:] hints
        cdef int board_width = board.get_width(), board_height = board.get_height()
        cdef int hint_sum, marked_sum, i
        
        for column_index in xrange(board_width):
            if board.is_column_complete(column_index):
                continue
            hints = board.get_column_hints(column_index)
            hint_sum = sum(hints)
            marked_sum = 0
            column = board.get_column(column_index)
            possible_moves = []
            for i in xrange(board_height):
                if column[i] == cellmarking.BLACK:
                    marked_sum += 1
                elif column[i] == cellmarking.NONE:
                    possible_moves.append(i)
            if marked_sum == hint_sum:
                for i in possible_moves:
                    moves.append(Move(column_index, i, cellmarking.WHITE, 'Completion', 'This column is complete, so the remaining spaces can be filled in.'))

        for row_index in xrange(board_height):
            if board.is_row_complete(row_index):
                continue
            hints = board.get_row_hints(row_index)
            hint_sum = sum(hints)
            marked_sum = 0
            row = board.get_row(row_index)
            possible_moves = []
            for i in xrange(board_width):
                if row[i] == cellmarking.BLACK:
                    marked_sum += 1
                elif row[i] == cellmarking.NONE:
                    possible_moves.append(i)
            if marked_sum == hint_sum:
                for i in possible_moves:
                    moves.append(Move(i, row_index, cellmarking.WHITE, 'Completion', 'This row is complete, so the remaining spaces can be filled in.'))
        
        Move.remove_dupes(moves)
        
        return moves
