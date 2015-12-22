from picross.models.cellmarking cimport *
from picross.models.markedblock cimport MarkedBlock


cdef list stack_left(list hints, list current_marks):
    cdef int board_length = len(current_marks), total_length
    cdef list stacked

    # Stack all the hints we have
    stacked, total_length = _stack_markedblocks(hints, board_length)

    if total_length == board_length:
        return stacked

    # We can use a faster algorithm if no blocks are already painted in the row
    cdef bint empty_row = True
    for i in xrange(board_length):
        if current_marks[i] > 0:
            empty_row = False
            break

    stacked = brute_force_stack(stacked, current_marks, len(stacked) - 1, 1)

    return stacked


cdef list stack_right(list hints, list current_marks):
    cdef int board_length = len(current_marks), total_length
    cdef list stacked

    # Stack all the hints we have
    stacked, total_length = _stack_markedblocks(hints, board_length)

    if total_length == board_length:
        return stacked

    # Update positions for the right stack
    cdef int position_difference = board_length - total_length
    cdef MarkedBlock block
    for block in stacked:
        block.position += position_difference

    cdef bint empty_row = True
    for i in xrange(board_length):
        if current_marks[i] > 0:
            empty_row = False
            break

    stacked = brute_force_stack(stacked, current_marks, 0, -1)

    return stacked


cdef list brute_force_stack(list stacked, list current_marks, int start_index, int step, bint find_next=False):
    cdef int block_index = start_index
    cdef int board_length = len(current_marks), block_count = len(stacked)
    cdef int previous_index, end_index, next_position, i
    cdef MarkedBlock current_block, previous_block, block
    
    if step < 0:
        end_index = -1
    else:
        end_index = block_count
    while find_next or _conflicts(stacked, current_marks):
        find_next = False
        current_block = stacked[block_index]
        if (step > 0 and current_block.position + current_block.length < board_length) or \
           (step < 0 and current_block.position > 0):
            current_block.position += step
        else:
            # Backtrack until we can move one of the previous blocks
            previous_index = block_index - step
            while True:
                if previous_index < 0 or previous_index >= block_count:
                    return None
                previous_block = stacked[previous_index]
                if step > 0:
                    if previous_block.position + previous_block.length + step < stacked[previous_index + step].position:
                        previous_block.position += step
                        next_position = previous_block.position + previous_block.length + step
                        i = previous_index + step
                        while i != end_index:
                            block = stacked[i]
                            block.position = next_position
                            next_position += step * block.length + step
                            i += step
                        break

                elif previous_block.position + step > stacked[previous_index + step].position + stacked[previous_index + step].length:
                    previous_block.position += step
                    i = previous_index + step
                    while i != end_index:
                        stacked[i].position = stacked[i - step].position - stacked[i].length + step
                        i += step
                    break
                previous_index -= step

    return stacked


cdef list blocks_to_array(list block_list, int board_width):
    cdef list result = []
    cdef int position = 0, i
    cdef MarkedBlock block
    
    for block in block_list:
        if block.position > position:
            for i in xrange(position, block.position):
                result.append(0)
            position = block.position
            
        if block.marking == BLACK:
            if block.hint_id != -1:
                marking = block.hint_id
            else:
                marking = 1
        elif block.marking == WHITE:
            marking = 0
        else:
            marking = -1
        for i in xrange(block.length):
            result.append(marking)
        position += block.length
    
    if position < board_width:
        for i in xrange(board_width - position):
            result.append(0)
    return result


cdef tuple _stack_markedblocks(list hints, int board_length):
    cdef list stacked = []
    cdef int total_length = 0, i, hint, hint_count = len(hints)
    for i in xrange(hint_count):
        hint = hints[i]
        stacked.append(MarkedBlock(BLACK, hint, hint_id=i + 1, position=total_length))
        total_length += hint
        if i != hint_count - 1:
            total_length += 1
    return stacked, total_length


cdef bint _conflicts(list marked_blocks, list correct_array):
    cdef int test_position = 0, block_position, i, correct
    cdef cell_marking marking
    cdef MarkedBlock block
    
    for block in marked_blocks:
        marking = block.marking
        block_position = block.position
        if block_position > test_position:
            # No block here means no marking, make sure there aren't any black blocks in the difference
            for i in xrange(test_position, block_position):
                if correct_array[i] > 0:
                    return True
            test_position = block_position
            
        for i in xrange(block.length):
            correct = correct_array[block_position + i]
            if (marking == BLACK and correct == 0) or (marking != BLACK and correct > 0):
                return True
        test_position += block.length
    
    cdef int last_index = len(correct_array)
    if test_position < last_index:
        for i in xrange(test_position, last_index):
            if correct_array[i] > 0:
                return True
    return False
