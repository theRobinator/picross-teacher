from cell import Cell
from cellmarking cimport *
from markedblock import MarkedBlock


cdef class Board(object):
    cdef int _width, _height
    cdef bint _hints_current
    cdef list _top_hints, _side_hints
    cdef list _cells
    cdef list _row_mark_counts, _col_mark_counts
    
    #: Get the width.
    cpdef int get_width(self)

    #: Get the height.
    cpdef int get_height(self)
    
    #: Get a list containing the markings of a single row.
    cpdef list get_row(self, int row)
    
    #: Get a list containing the markings of a single column.
    cpdef list get_column(self, int column)
    
    #: Get the current mark of the given cell.
    cpdef cell_marking get_mark(self, int x, int y)

    #: Set the current mark of the given cell.
    cpdef void mark_cell(self, int x, int y, cell_marking mark)

    cpdef cell_marking get_answer(self, int x, int y)

    #: Set the answer value of the given cell.
    cpdef void set_answer(self, int x, int y, cell_marking mark)
    
    #: Set the hints for the puzzle.
    cpdef void set_hints(self, list top_hints, list side_hints)

    #: Get the hints for row i.
    cpdef int[:] get_row_hints(self, int i)

    #: Get the hints for column i.
    cpdef int[:] get_column_hints(self, int i)

    #: Refresh the hints to a correct state. This should be called after modifying the answer.
    cpdef void refresh_hints(self)

    cpdef str get_display_string(self, bint answer=?)
    
    #: Check to see if a row is complete.
    cpdef bint is_row_complete(self, int row)
    
    #: Check to see if a column is complete.
    cpdef bint is_column_complete(self, int column)
