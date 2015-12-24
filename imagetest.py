import pyximportcpp; pyximportcpp.install(inplace=True)

from sys import argv

from PIL import Image
from picross.io import imageio


if len(argv) < 2:
    print 'Usage: imagetest.py <image_file>'
    exit(1)

image = Image.open(argv[1])
board = imageio.board_from_image(image, 35, 35)
print board.get_display_string(True)