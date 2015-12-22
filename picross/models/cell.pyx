from cellmarking cimport *


cdef class Cell(object):
    cpdef cell_marking _marking
    cpdef cell_marking _answer

    def __cinit__(self):
        self._marking = NONE
        self._answer = NONE

    cpdef cell_marking get_marking(self):
        return self._marking

    cpdef set_marking(self, cell_marking marking):
        self._marking = marking

    cpdef cell_marking get_answer(self):
        return self._answer

    cpdef set_answer(self, cell_marking marking):
        self._answer = marking
