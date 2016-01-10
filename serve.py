#! /usr/bin/env python2.7
#import pyximportcpp; pyximportcpp.install(inplace=True)

import json
import re
from os import path, listdir
from sys import argv

import cherrypy

from picross.io import jsonio, load_board

from picross.solvers.bruteforce import BruteForce
from picross.solvers.finalspaces import FinalSpaces
from picross.solvers.multisolver import MultiSolver
from picross.solvers.simpleboxes import SimpleBoxes


SERVER_ROOT = 'server'
PUZZLE_DIR = path.join('static', 'puzzles')
DEFAULT_WIDTH = 35
DEFAULT_HEIGHT = 35
SUPPORTED_FILE_TYPES = {'.txt', '.jpg', '.gif', '.png'}


class PicrossServer(object):
    
    def __init__(self, puzzle_name='15x15_puppy'):
        self.puzzle_name = puzzle_name
        self.solver = MultiSolver([
            FinalSpaces(),
            SimpleBoxes(),
            BruteForce()
        ])
        self.name_regex = re.compile('^(\d+)x(\d+)_([\d\w]+)(\.txt)?')
    
    @cherrypy.expose
    def index(self, puzzle=None):
        # Load the correct puzzle
        if puzzle is None:
            puzzle = self.puzzle_name

        image_width = DEFAULT_WIDTH
        image_height = DEFAULT_HEIGHT
        image_url = None
        if '.' not in puzzle:
            puzzle += '.txt'
        elif not puzzle.endswith('.txt'):
            image_url = path.join(PUZZLE_DIR, puzzle)
            match = re.match(self.name_regex, puzzle)
            if match is not None:
                image_width, image_height, _, __ = match.groups()
                image_width = int(image_width)
                image_height = int(image_height)
        try:
            board = load_board(path.join(SERVER_ROOT, PUZZLE_DIR, puzzle), image_width, image_height)
        except IOError, err:
            print err
            return 'Could not read from the requested file. <a href="/">Back</a>'
        
        # Get the available puzzles
        puzzle_files = listdir(path.join(SERVER_ROOT, PUZZLE_DIR))
        other_puzzle_lines = []
        
        for filename in puzzle_files:
            extension = path.splitext(filename)[1]
            if extension not in SUPPORTED_FILE_TYPES:
                continue
            match = re.match(self.name_regex, filename)
            if match is not None:
                x, y, name, _ = match.groups()
                name = name.replace('_', ' ').title()
            else:
                x = DEFAULT_WIDTH
                y = DEFAULT_HEIGHT
                name = filename
            other_puzzle_lines.append((int(x), int(y), '<li><a href="/?puzzle=%s">(%s x %s) %s</a></li>' % (filename, x, y, name)))
        
        other_puzzle_html = [i[2] for i in sorted(other_puzzle_lines)]
        
        # Get the html file
        with open(path.join(SERVER_ROOT, 'index.html')) as fp:
            contents = fp.read()
        
        # Render the template with params
        params = {
            'boardJson': jsonio.board_to_json(board),
            'imageFile': json.dumps(image_url),
            'availablePuzzles': ''.join(other_puzzle_html)
        }
        return contents % params
    
    @cherrypy.expose
    def get_hints(self, board_str=None):
        board = jsonio.json_to_board(board_str)
        if board is None:
            return '{"error": "Failed to load puzzle"}'
        else:
            try:
                moves = self.solver.get_next_moves(board)
                return jsonio.moves_to_json(moves)
            except Exception, e:
                print e
                return '{"error": "Can\'t find a solution for this puzzle."}'


if __name__ == '__main__':
    conf = {
        '/': {
            'tools.staticdir.root': path.abspath(SERVER_ROOT)
        },
        '/static': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'static'
        }
    }
    if len(argv) > 1:
        server = PicrossServer(argv[1])
    else:
        server = PicrossServer()
    cherrypy.quickstart(server, '/', conf)
