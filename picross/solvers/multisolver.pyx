from picross.models.board cimport Board

cdef class MultiSolver(object):
    cdef list _solvers
    
    def __init__(self, solvers):
        self._solvers = solvers
    
    cpdef list get_next_moves(self, Board board):
        cdef list moves
        for solver in self._solvers:
            moves = solver.get_next_moves(board)
            if len(moves) > 0:
                return moves
        return []
