import math

from PIL import Image

from picross.models import cellmarking
from picross.models.board import Board


def board_from_image(image, width, height):
    """ Create a board object from a PIL image.
    :param image: 
    :return: 
    """
    if image.mode != 'RGB':
        image = image.convert('RGB')

    # Crop image to the same ratio as width x height
    image_width, image_height = image.size
    if image_width == width and image_height == height:
        sized_image = image
    else:
        desired_ratio = float(width) / height
        image_ratio = float(image_width) / image_height
        if desired_ratio == image_ratio:
            cropped_image = image
        else:
            if desired_ratio > image_ratio:
                # Decrease height to increase ratio
                new_width = image_width
                new_height = image_width / desired_ratio
            else:
                # Decrease width to decrease ratio
                new_width = image_height * desired_ratio
                new_height = image_height
            
            x_crop_distance = int((image_width - new_width) / 2)
            y_crop_distance = int((image_height - new_height) / 2)
            crop_rect = (
                x_crop_distance,  # Left
                y_crop_distance,  # Top
                image_width - x_crop_distance,  # Right
                image_height - y_crop_distance  # Bottom
            )
            cropped_image = image.crop(crop_rect)
    
        # Resize image to width x height
        sized_image = cropped_image.resize((width, height), Image.ANTIALIAS)
    
    # Fill in cells based on luminosity value of pixels
    min_luma = 255
    max_luma = 0
    luminances = []
    for y in xrange(height):
        for x in xrange(width):
            r, g, b = sized_image.getpixel((x, y))
            # HSP color model's lunimance formula: http://alienryderflex.com/hsp.html
            luma = math.sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b)
            if luma < min_luma:
                min_luma = luma
            if luma > max_luma:
                max_luma = luma
            luminances.append(luma)
    
    luma_threshold = (max_luma - min_luma) / 2
    board = Board(width, height)
    for y in xrange(height):
        for x in xrange(width):
            luma = luminances[y * width + x]
            if luma > luma_threshold:
                marking = cellmarking.WHITE
            else:
                marking = cellmarking.BLACK
            board.set_answer(x, y, marking)
    
    board.refresh_hints()
    return board


def puzzle_from_image_file(filename, width, height):
    return board_from_image(Image.open(filename), width, height)
