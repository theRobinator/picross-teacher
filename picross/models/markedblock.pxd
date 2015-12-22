from cellmarking cimport cell_marking

cdef class MarkedBlock:
    cpdef public cell_marking marking
    cpdef public int length, hint_id, position
