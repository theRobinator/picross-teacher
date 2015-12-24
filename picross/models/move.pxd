from cellmarking cimport cell_marking

cdef class Move(object):
    cdef public int x, y
    cdef public cell_marking marking
    cdef public str name, description
