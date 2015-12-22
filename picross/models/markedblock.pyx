cdef class MarkedBlock:
    def __init__(self, marking, length=0, hint_id=-1, position=-1):
        self.marking = marking
        self.length = length
        self.hint_id = hint_id
        self.position = position

    def __str__(self):
        innards = 'marking=%s, length=%d' % (self.marking, self.length)
        if self.position > -1:
            innards += ', position=%d' % self.position
        return 'MarkedBlock(%s)' % innards
