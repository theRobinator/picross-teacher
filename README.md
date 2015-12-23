# Picross-teacher

Picross-teacher is a program that teaches users how to solve Picross puzzles,
also known as [nonograms](https://en.wikipedia.org/wiki/Nonogram). It currently
supports the following strategies:

* **Simple boxes**: When a hint is larger than half of the space it belongs in,
  the middle cells can be filled in. This is because there is no possible way to
  avoid filling them in.
* **Simple spaces**: The opposite of simple boxes; when cells are already filled
  in a row, cells that are too far away to be filled can be marked as spaces.
* **Punctuation**: When a block of cells is completed, it can be surrounded by
  spaces.
* **Completion**: When all hints have been satisfied, the remaining cells can be
  marked as spaces.
* **Forced boxes**: A more complex version of simple boxes; when placing a space
  in a given cell would lead to an unsolvable puzzle, the cell must be filled.
* **Inner spaces**: A more complex version of simple spaces; when multiple cells
  are filled in a row, spaces in between them can be marked as spaces if no
  possible positioning of filled blocks covers them.

As far as I can tell, these methods combined can solve every puzzle that doesn't
require logic chains (which are too hard for humans anyway, IMO).


## Running

This program is written in [Cython](http://cython.org), which means that you'll
need Cython installed in order to use it. Once you have it, run

```python setup.py compile```

to compile, then run

```python test.py <puzzle_file_name>```

to solve a puzzle from the test puzzles folder.


## Roadmap

* Local server + web interface for interactive solving
* Make your own puzzles from images