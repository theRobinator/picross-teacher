from cell import Cell
from cellmarking cimport *
from markedblock import MarkedBlock


cdef class Board(object):
    def __init__(self, int width, int height):
        self._width = width
        self._height = height
        self._hints_current = False

        self._top_hints = []
        self._side_hints = []
        
        self._row_mark_counts = [0] * height
        self._col_mark_counts = [0] * width

        cells = []
        for i in range(width):
            next_row = []
            for j in range(height):
                next_row.append(Cell())
            cells.append(next_row)
        self._cells = cells

    #: Get the width.
    cpdef int get_width(self):
        return self._width

    #: Get the height.
    cpdef int get_height(self):
        return self._height

    #: Iterate through a row using MarkedBlocks
    def iterrow(self, row):
        cdef cell_marking last_marking = self._cells[0][row].get_marking()
        cdef int length = 0
        block = MarkedBlock(last_marking, position=0)

        for i in xrange(self._width):
            cell = self._cells[i][row]

            if cell.get_marking() != last_marking:
                yield block
                last_marking = cell.get_marking()
                block = MarkedBlock(last_marking, position=i)

            block.length += 1

        if block is not None:
            yield block

    #: Iterate through a row using MarkedBlocks
    def itercolumn(self, column):
        cdef cell_marking last_marking = self._cells[column][0].get_marking()
        cdef int length = 0
        block = MarkedBlock(last_marking, position=0)

        for i in xrange(self._height):
            cell = self._cells[column][i]

            if cell.get_marking() != last_marking:
                yield block
                last_marking = cell.get_marking()
                block = MarkedBlock(last_marking, position=i)

            block.length += 1

        if block is not None:
            yield block
    
    #: Get a list containing the markings of a single row.
    cpdef list get_row(self, int row):
        result = []
        for i in xrange(self._width):
            result.append(self._cells[i][row].get_marking())
        return result
    
    #: Get a list containing the markings of a single row.
    cpdef list get_column(self, int column):
        result = []
        for i in xrange(self._height):
            result.append(self._cells[column][i].get_marking())
        return result
    
    cpdef bint is_row_complete(self, int row):
        return self._row_mark_counts[row] == self._width
    
    cpdef bint is_column_complete(self, int column):
        return self._col_mark_counts[column] == self._height
    
    #: Get the current mark of the given cell.
    cpdef cell_marking get_mark(self, int x, int y):
        return self._cells[x][y].get_marking()

    #: Set the current mark of the given cell.
    cpdef void mark_cell(self, int x, int y, cell_marking mark):
        if mark == NONE:
            self._row_mark_counts[y] -= 1
            self._col_mark_counts[x] -= 1
        else:
            self._row_mark_counts[y] += 1
            self._col_mark_counts[x] += 1
        self._cells[x][y].set_marking(mark)

    cpdef cell_marking get_answer(self, int x, int y):
        return self._cells[x][y].get_answer()

    #: Set the answer value of the given cell.
    cpdef void set_answer(self, int x, int y, cell_marking mark):
        if self._cells[x][y].get_answer() != mark:
            self._hints_current = False
        self._cells[x][y].set_answer(mark)
        
    # #: Set the hints for the puzzle. This should only be called when the puzzle is empty, otherwise you'll get unexpected results.
    cpdef void set_hints(self, list top_hints, list side_hints):
        self._top_hints = top_hints
        self._side_hints = side_hints
        self._hints_current = True

    #: Get the hints for row i.
    cpdef list get_row_hints(self, int i):
        return self._side_hints[i]

    #: Get the hints for column i.
    cpdef list get_column_hints(self, int i):
        return self._top_hints[i]

    #: Refresh the hints to a correct state. This should be called after modifying the answer.
    cpdef void refresh_hints(self):
        if self._hints_current:
            return
        
        cdef int row, column, mark_count
        cdef list hints, col_list
        cdef cell_marking answer

        # Side hints
        self._side_hints = []
        for column in xrange(self._width):
            hints = []
            mark_count = 0
            for row in xrange(self._height):
                answer = self._cells[row][column].get_answer()
                if answer == BLACK:
                    mark_count += 1
                elif answer == WHITE:
                    if mark_count > 0:
                        hints.append(mark_count)
                        mark_count = 0
            if mark_count > 0:
                hints.append(mark_count)
            self._side_hints.append(hints)

        # Top hints
        self._top_hints = []
        for col_list in self._cells:
            hints = []
            mark_count = 0
            for cell in col_list:
                answer = cell.get_answer()
                if answer == BLACK:
                    mark_count += 1
                elif answer == WHITE:
                    if mark_count > 0:
                        hints.append(mark_count)
                        mark_count = 0
            if mark_count > 0:
                hints.append(mark_count)
            self._top_hints.append(hints)
        
        self._hints_current = True


    cpdef str get_display_string(self, bint answer=False):
        if not self._hints_current:
            self.refresh_hints()

        cdef int i, missed_checks, max_len, this_len, col_width
        cdef cell_marking mark
        cdef str printed_list, left_buffer, horiz_divider, top_hint_str
        cdef list row, board_lines = [], top_hints = [], top_print_list, hint_list, side_print_list
        
        # Make top hints
        top_print_list = []
        i = 0
        col_width = 2
        while True:
            missed_checks = 0
            nth_hints = []
            for hint_list in self._top_hints:
                if i < len(hint_list):
                    str_hint = str(hint_list[len(hint_list) - 1 - i])
                    col_width = max(col_width, len(str_hint))
                    nth_hints.append(str_hint)
                else:
                    nth_hints.append(' ')
                    missed_checks += 1
            if missed_checks == self._width:
                break
            i += 1
            top_print_list.insert(0, nth_hints)

        for hint_list_index in xrange(len(top_print_list)):
            hint_list = top_print_list[hint_list_index]
            for i in xrange(len(hint_list)):
                this_len = len(hint_list[i])
                if this_len < col_width:
                    hint_list[i] = (' ' * (col_width - this_len)) + hint_list[i]
            top_print_list[hint_list_index] = '|'.join(hint_list)
        
        # Make side hints
        side_print_list = []
        max_len = 0
        for hint_list in self._side_hints:
            printed_list = ' '.join([str(i) for i in hint_list])
            side_print_list.append(printed_list)
            max_len = max(max_len, len(printed_list))

        for i in xrange(len(side_print_list)):
            this_len = len(side_print_list[i])
            if this_len < max_len:
                side_print_list[i] = (' ' * (max_len - this_len)) + side_print_list[i]

        left_buffer = ' ' * max_len + ' '

        # board_lines
        line_color = '\033[37m'
        reset_color = '\033[0m'
        horiz_divider = line_color + left_buffer + '+' + ((('-' * col_width) + '+') * self._width) + reset_color
        vert_divider = line_color + '|' + reset_color

        board_lines.append(horiz_divider)

        for h in range(self._height):
            row = [vert_divider]
            for w in range(self._width):
                if answer:
                    mark = self.get_answer(w, h)
                else:
                    mark = self.get_mark(w, h)
                if mark == NONE:
                    row.append(' ' * col_width)
                elif mark == BLACK:
                    row.append('\033[42m' + ' ' * col_width + reset_color)
                elif mark == WHITE:
                    row.append('\033[34m' + 'x' * col_width + reset_color)
                row.append(vert_divider)

            board_lines.append(side_print_list[h] + ' ' + ''.join(row))
            board_lines.append(horiz_divider)

        top_hint_str = left_buffer + ' ' + ("\n" + left_buffer + ' ').join(top_print_list) + "\n"
        return top_hint_str + "\n".join(board_lines)

    def __str__(self):
        return self.get_display_string()
