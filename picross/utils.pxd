cdef list stack_left(list hints, int[:] current_marks)
cdef list stack_right(list hints, int[:] current_marks)
cdef list brute_force_stack(list stacked, int[:] current_marks, int start_index, int step, bint find_next=?)
cdef int[:] blocks_to_array(list block_list, int board_width)
cdef tuple _stack_markedblocks(list hints, int board_length)
cdef bint _conflicts(list marked_blocks, int[:] correct_array)