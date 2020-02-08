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

```
python setup.py develop  # Only the first time
python setup.py compile --inplace  # Every time
```

to compile. After you do that, you can run

```python serve.py```

to launch the web interface at http://localhost:8080.


## Making your own puzzles

You can add your own puzzles to the web interface by creating new files in the
`puzzles` directory. These files' names follow a pattern of `<WIDTH>x<HEIGHT>_<PUZZLE_NAME>`.
There are three different file types that are supported:

### Hints only

A hints-only file contains the hints for the top of the puzzle, one line per column,
then a blank line, then the hints for the left side of the puzzle. For example,

```
1 3
5

1
1
1
```

Creates a 3x2 puzzle with "1 3" and "5" as the hints on the top, and "1" for each row.

### Puzzle ASCII art

An art file contains an actual drawing of the puzzle, using spaces for spaces and any
non-space character for filled blocks. For example,

```
#####
# # #
#####
# # #
#####
```
Creates a 5x5 puzzle and fills the hints in for you.

### Image file

Placing a JPG, PNG, or GIF file in the `puzzles` directory will generate a puzzle from
the contents of the image. Filled blocks and spaces are chosen based on lighter or
darker colors. When creating a puzzle from an image, it's best to use one with only
2 or 3 colors.


## Roadmap

* Create pre-compiled distros
* Get more puzzles by default