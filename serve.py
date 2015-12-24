#! /usr/bin/env python2.7
import pyximport; pyximport.install(inplace=True)

from os import path
from sys import argv

import cherrypy

from picross.io import jsonio, load_board

from picross.solvers.bruteforce import BruteForce
from picross.solvers.finalspaces import FinalSpaces
from picross.solvers.multisolver import MultiSolver
from picross.solvers.simpleboxes import SimpleBoxes


SERVER_ROOT = 'server'

class PicrossServer(object):
    
    def __init__(self, puzzle_name=path.join('testpuzzles', '15x15_puppy.txt')):
        self.puzzle_name = puzzle_name
        self.solver = MultiSolver([
            FinalSpaces(),
            SimpleBoxes(),
            BruteForce()
        ])
    
    @cherrypy.expose
    def index(self):
        with open(path.join(SERVER_ROOT, 'index.html')) as fp:
            contents = fp.read()
        board = load_board(self.puzzle_name)
        params = {
            'boardJson': jsonio.board_to_json(board)
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
