#cython: wraparound=False

from picross cimport utils
from picross.models.board cimport Board
from picross.models.cellmarking cimport cell_marking
from picross.models.markedblock cimport MarkedBlock
from picross.models.move cimport Move

from picross.models import cellmarking
from picross import utils


cdef class SimpleBoxes(object):
    """ The SimpleBoxes pass looks for rows and columns where hints are larger than half the available space. This
        allows us to guarantee that the boxes in the middle are painted black.
    """
    cpdef list get_next_moves(self, Board board):
        cdef int board_width = board.get_width()
        cdef int board_height = board.get_height()
        cdef int i, row_index, column_index
        cdef MarkedBlock block
        cdef list moves = [], current_row, left_stacked, right_stacked
        cdef int[:] hints, current_array, left_array, right_array
        
        for row_index in xrange(board_height):
            if board.is_row_complete(row_index):
                continue
            hints = board.get_row_hints(row_index)
            # Get the row with currently filled-in cells
            current_row = []
            for block in board.iterrow(row_index):
                current_row.append(block)
            current_array = utils.blocks_to_array(current_row, board_width)

            # Create left- and right-stacked versions of all the hints
            left_stacked = utils.stack_left(hints, current_array)
            right_stacked = utils.stack_right(hints, current_array)
            if left_stacked == None or right_stacked == None:
                raise Exception('Could not stack for row %d' % row_index)

            left_array = utils.blocks_to_array(left_stacked, board_width)
            right_array = utils.blocks_to_array(right_stacked, board_width)

            # Find places where the two stackings fit together
            for i in xrange(len(left_array)):
                if left_array[i] == right_array[i] and left_array[i] > 0 and current_array[i] == -1:
                    moves.append(Move(i, row_index, cellmarking.BLACK, 'Simple Boxes', 'This cell is marked regardless of the position of hints in this row.'))
            
            moves.extend(self._punctuate(hints, current_array, left_array, right_array, True, row_index))
            moves.extend(self._find_spaces(current_array, left_array, right_array, True, row_index))
            
        for column_index in xrange(board_width):
            if board.is_column_complete(column_index):
                continue
                
            hints = board.get_column_hints(column_index)
            # Get the column with currently filled-in cells
            current_row = []
            for block in board.itercolumn(column_index):
                current_row.append(block)
            current_array = utils.blocks_to_array(current_row, board_height)

            # Create left- and right-stacked versions of all the hints
            left_stacked = utils.stack_left(hints, current_array)
            right_stacked = utils.stack_right(hints, current_array)
            if left_stacked == None or right_stacked == None:
                raise Exception('Could not stack for column %d' % column_index)

            left_array = utils.blocks_to_array(left_stacked, board_height)
            right_array = utils.blocks_to_array(right_stacked, board_height)

            # Find places where the two stackings fit together
            for i in xrange(len(left_array)):
                if left_array[i] == right_array[i] and left_array[i] > 0 and current_array[i] == -1:
                    moves.append(Move(column_index, i, cellmarking.BLACK, 'Simple Boxes', 'This cell is marked regardless of the position of hints in this column.'))
            
            moves.extend(self._punctuate(hints, current_array, left_array, right_array, False, column_index))
            moves.extend(self._find_spaces(current_array, left_array, right_array, False, column_index))
            
        Move.remove_dupes(moves)
            
        return moves

    cdef list _punctuate(self, int[:] hints, int[:] current_array, int[:] left_array, int[:] right_array, bint is_rows, int board_index):
        # Punctuate fully-discovered blocks with spaces
        cdef list moves = []
        cdef int current_hint = 0, match_count = 0, matches_needed = 0, i, x1, x2, y1, y2
        
        cdef str move_label
        if is_rows:
            move_label = 'row'
        else:
            move_label = 'column'
            
        for i in xrange(len(left_array)):
            marking = left_array[i]
            if marking == 0:
                if match_count == matches_needed and match_count > 0:
                    reason = 'The block of %d in this %s is complete, so it can be surrounded by spaces.' % (match_count, move_label)
                    previous_index = i - match_count - 1
                    if is_rows:
                        x1 = previous_index
                        x2 = i
                        y1 = y2 = board_index
                    else:
                        x1 = x2 = board_index
                        y1 = previous_index
                        y2 = i
                    if previous_index >= 0 and current_array[previous_index] == -1:
                        moves.append(Move(x1, y1, cellmarking.WHITE, 'Punctuation', reason))
                    if current_array[i] == -1:
                        moves.append(Move(x2, y2, cellmarking.WHITE, 'Punctuation', reason))
                current_hint = 0
                match_count = 0
                
            elif marking == current_hint and marking == right_array[i]:
                match_count += 1
            
            elif marking == right_array[i]:
                current_hint = marking
                matches_needed = hints[marking - 1]
                match_count = 1
            else:
                current_hint = 0
                match_count = 0
        
        if match_count == matches_needed and match_count > 0:
            reason = 'The block of %d in this %s is complete, so it can be surrounded by spaces.' % (match_count, move_label)
            previous_index = i - match_count
            if is_rows:
                x1 = previous_index
                y1 = board_index
            else:
                x1 = board_index
                y1 = previous_index
            if previous_index >= 0 and current_array[previous_index] == -1:
                moves.append(Move(x1, y1, cellmarking.WHITE, 'Punctuation', reason))
        
        return moves
    
    cdef list _find_spaces(self, int[:] current_array, int[:] left_array, int[:] right_array, bint is_rows, int board_index):
        cdef list moves = []
        cdef str label
        cdef int left_marking, right_marking, x, y, i
    
        if is_rows:
            label = 'This cell is empty regardless of the position of hints in this row.'
        else:
            label = 'This cell is empty regardless of the position of hints in this column.'
            
        # Any shared spaces outside both stackings can be filled in
        for i in xrange(len(left_array)):
            left_marking = left_array[i]
            right_marking = right_array[i]
            if left_marking > 0 or right_marking > 0:
                break
            if current_array[i] == -1:
                if is_rows:
                    x = i
                    y = board_index
                else:
                    x = board_index
                    y = i
                moves.append(Move(x, y, cellmarking.WHITE, 'Simple Spaces', label))

        for i in xrange(len(left_array) - 1, -1, -1):
            left_marking = left_array[i]
            right_marking = right_array[i]
            if left_marking > 0 or right_marking > 0:
                break
            if current_array[i] == -1:
                if is_rows:
                    x = i
                    y = board_index
                else:
                    x = board_index
                    y = i
                moves.append(Move(x, y, cellmarking.WHITE, 'Simple Spaces', label))

        return moves
