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
need a C compiler installed in order to build it. Once you have that, run

```python setup.py compile --inplace```

to compile. After you do that, you can either run

```python test.py [puzzle_file_name]```

to solve a puzzle from the test puzzles folder, or

```python serve.py [puzzle_file_name]```

to start up the local webserver with the web interface at http://localhost:8080.


## Roadmap

* Make your own puzzles from images
* Use native arrays instead of lists for speed
* Create pre-compiled distros