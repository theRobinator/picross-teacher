def load_board(filename, image_width=40, image_height=40):
    if filename.endswith('.txt'):
        import textio
        return textio.puzzle_from_file(filename)
    else:
        import imageio
        return imageio.puzzle_from_image_file(filename, image_width, image_height)
