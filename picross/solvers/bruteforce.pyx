#cython: boundscheck=False, nonecheck=False, wraparound=False, initializedcheck=False
from picross.models.board cimport Board

from picross.models.cellmarking cimport *
from picross.models.move cimport Move
from picross cimport utils


cdef class BruteForce(object):
    
    cpdef get_next_moves(self, Board board):
        cdef int board_width = board.get_width()
        cdef int board_height = board.get_height()
        cdef int row_index, column_index
        cdef int[:] hints, current_array
        cdef list moves = []
        
        for row_index in xrange(board_height):
            if board.is_row_complete(row_index):
                continue
            
            hints = board.get_row_hints(row_index)
            current_marks = board.get_row_blocks(row_index)
            current_array = utils.blocks_to_array(current_marks, board_width)
            
            moves.extend(self._get_possible_marks(hints, current_array, board_width, True, row_index))
        
        for column_index in xrange(board_width):
            if board.is_column_complete(column_index):
                continue
            
            hints = board.get_column_hints(column_index)
            current_marks = board.get_column_blocks(column_index)
            current_array = utils.blocks_to_array(current_marks, board_height)
            
            moves.extend(self._get_possible_marks(hints, current_array, board_height, False, column_index))

        Move.remove_dupes(moves)
            
        return moves
    
    cdef list _get_possible_marks(self, int[:] hints, int[:] current_array, int board_size, bint is_rows, int board_index):
        cdef list moves = []
        cdef str move_suffix, move_name
        cdef list stacked
        cdef int[:] possible_marks, new_array
        cdef int marks_remaining, i, x, y, marking
        
        if is_rows:
            move_suffix = 'row'
        else:
            move_suffix = 'column'
        cdef str spaces_name = 'Inner Spaces'
        cdef str spaces_label = 'The blocks in this %s cannot reach to this cell, so it must be empty.' % move_suffix
        cdef str boxes_name = 'Forced Boxes'
        cdef str boxes_label = 'This cell is filled no matter how this %s is filled in.' % move_suffix
        
        stacked = utils.stack_left(hints, current_array)
        possible_marks = utils.blocks_to_array(stacked, board_size)
        marks_remaining = 0
        for i in xrange(board_size):
            if i != -1:
                marks_remaining += 1
        
        cdef bint looping = True
        cdef int stack_end_index = len(stacked) - 1
        while looping:
            stacked = utils.brute_force_stack(stacked, current_array, stack_end_index, 1, True)
            if stacked is None:
                break
            new_array = utils.blocks_to_array(stacked, board_size)
            for i in xrange(board_size):
                if possible_marks[i] != new_array[i] and possible_marks[i] != -1:
                    possible_marks[i] = -1
                    marks_remaining -= 1
                    if marks_remaining == 0:
                        looping = False
                        break
        
        for i in xrange(board_size):
            marking = possible_marks[i]
            if marking != -1 and current_array[i] == -1:
                if marking == 0:
                    cell_marking = WHITE
                    move_name = spaces_name
                    label = spaces_label
                else:
                    cell_marking = BLACK
                    move_name = boxes_name
                    label = boxes_label
                if is_rows:
                    x = i
                    y = board_index
                else:
                    x = board_index
                    y = i
                moves.append(Move(x, y, cell_marking, move_name, label))
        
        return moves