cimport Move
import cellmarking


cdef class Move(object):
    
    def __init__(self, x, y, mark, name, description):
        self.x = x
        self.y = y
        self.marking = mark
        self.name = name
        self.description = description

    def __str__(self):
        if self.marking == cellmarking.BLACK:
            mark = 'Fill'
        elif self.marking == cellmarking.WHITE:
            mark = 'X'
        else:
            mark = None
        if mark is not None:
            return '[%s] %s at (%d, %d): %s' % (self.name, mark, self.x, self.y, self.description)
        else:
            return '[%s] Unknown at (%d, %d)' % (self.name, self.x, self.y)

    @staticmethod
    def remove_dupes(list moves):
        cdef set marked_positions = set()
        cdef int i = 0
        cdef Move move
        move_count = len(moves)
        while i < move_count:
            move = moves[i]
            move_position = (move.x, move.y)
            if move_position in marked_positions:
                del moves[i]
                move_count -= 1
            else:
                marked_positions.add(move_position)
                i += 1
            
        return moves
