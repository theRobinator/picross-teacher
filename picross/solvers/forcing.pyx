from picross.models.board cimport Board
from picross.models.cellmarking cimport cell_marking
from picross.models.markedblock cimport MarkedBlock

from picross.models import cellmarking
from picross.models.move import Move


cdef class Forcing(object):
    
    cpdef list get_next_moves(self, Board board):
        cdef int board_width = board.get_width()
        cdef int board_height = board.get_height()
        cdef int row_index, column_index
        cdef list moves = [], blocks
        
        for row_index in xrange(board_height):
            if board.is_row_complete(row_index):
                continue
            hints_remaining = board.get_row_hints(row_index)
            blocks = []
            for block in board.iterrow(row_index):
                blocks.append(block)
            moves.extend(self._force_cells(hints_remaining, blocks, True, row_index))
        
        for column_index in xrange(board_width):
            if board.is_column_complete(column_index):
                continue
            hints_remaining = board.get_column_hints(column_index)
            blocks = []
            for block in board.itercolumn(column_index):
                blocks.append(block)
            moves.extend(self._force_cells(hints_remaining, blocks, False, column_index))
            
        Move.remove_dupes(moves)
            
        return moves
                
    cdef _force_cells(self, list hints_remaining, list blocks, bint is_row, int board_index):
        cdef cell_marking last_mark = cellmarking.WHITE, next_mark
        cdef int block_count = len(blocks)
        cdef int max_int = 2 ** 31
        cdef int left_cut = 0
        cdef int right_cut = len(hints_remaining)
        cdef list moves = []
        
        cdef bint found
        cdef int block_index, min_hint, possible_length, i, x, y
        cdef str move_subtitle
        cdef MarkedBlock block
        
        if is_row:
            move_subtitle = ': rows'
        else:
            move_subtitle = ': columns'
        # Remove hints that are connected to the borders from the start
        for block_index in xrange(block_count):
            block = blocks[block_index]
            if block.marking == cellmarking.NONE:
                break
            
            next_mark = cellmarking.WHITE
            if block_index + 1 < block_count:
                next_mark = blocks[block_index + 1].marking
            
            if next_mark == cellmarking.WHITE and block.marking == cellmarking.BLACK:
                for i in xrange(len(hints_remaining)):
                    if hints_remaining[i] == block.length:
                        left_cut = i + 1
                        break
        
        # Remove hints that are connected to the borders from the end
        for block_index in xrange(block_count - 1, -1, -1):
            block = blocks[block_index]
            if block.marking == cellmarking.NONE:
                break

            next_mark = cellmarking.WHITE
            if block_index - 1 > 0:
                next_mark = blocks[block_index - 1].marking

            if next_mark == cellmarking.WHITE and block.marking == cellmarking.BLACK:
                for i in xrange(len(hints_remaining)):
                    if hints_remaining[i] == block.length:
                        if i > left_cut:
                            right_cut = i
                        break

        hints_remaining = hints_remaining[left_cut:right_cut]
        if len(hints_remaining) == 0:
            min_hint = max_int
        else:
            min_hint = min(hints_remaining)
        
        for block_index in xrange(block_count):
            block = blocks[block_index]
            next_mark = cellmarking.WHITE
            if block_index + 1 < block_count:
                next_mark = blocks[block_index + 1].marking
                
            if last_mark == cellmarking.WHITE and next_mark == cellmarking.WHITE:
                if block.marking == cellmarking.NONE and block.length < min_hint:
                    # Nothing can fit here
                    for i in xrange(block.length):
                        if is_row:
                            x = block.position + i
                            y = board_index
                        else:
                            x = board_index
                            y = block.position + i
                        moves.append(Move(x, y, cellmarking.WHITE, 'Forcing' + move_subtitle, 'No hint can fit in this gap, so it can be filled in'))
                        
                elif block.marking == cellmarking.BLACK:
                    # This is a complete block, we can remove possible blocks from the hints
                    block_length = block.length
                    for i in xrange(len(hints_remaining)):
                        if hints_remaining[i] == block_length:
                            if left_cut < i < right_cut:
                                hints_remaining = hints_remaining[i+1:]
                                if len(hints_remaining) == 0:
                                    min_hint = max_int
                                else:
                                    min_hint = min(hints_remaining)
                            break
            
            elif last_mark == cellmarking.BLACK and next_mark == cellmarking.BLACK and block.length == 1 and block.marking == cellmarking.NONE:
                possible_length = 1 + blocks[block_index - 1].length + blocks[block_index + 1].length
                found = False
                for hint in hints_remaining:
                    if hint >= possible_length:
                        found = True
                        break
                if not found:
                    if is_row:
                        x = block.position
                        y = board_index
                    else:
                        x = board_index
                        y = block.position
                    moves.append(Move(x, y, cellmarking.WHITE, 'Splitting' + move_subtitle, 'Marking here would cause a block of %d, which is too large, so it must not be marked' % possible_length))
            
            last_mark = block.marking
        return moves
