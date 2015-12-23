import os
from os import path
import shutil

from distutils.cmd import Command
from distutils.command.build_ext import build_ext
from setuptools import setup


class CleanCommand(Command):
    description = 'Clean up /build and any compiled output in the main tree.'
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        """ Get rid of everything that we built. """
        if path.exists('build'):
            shutil.rmtree('build')

        # Walk the directory structure and get the files we care about
        built_files = []
        for root, dirs, files in os.walk("."):
            # Get all the py and pyx files for compiling
            for filename in files:
                if filename.endswith('.c') or filename.endswith('.h') or filename.endswith('.so') or filename.endswith('.dll'):
                    os.unlink(path.join(root, filename))

            # Skip hidden directories
            i = 0
            while i < len(dirs):
                if dirs[i][0] == '.':
                    del dirs[i]
                else:
                    i += 1


class CompileCommand(build_ext):
    description = 'Compile all Python & Cython files into .so or .dll files.'

    def run(self):
        # Inline imports because we need setuptools to install this module first
        from Cython.Build import cythonize
        from Cython.Build.Dependencies import create_extension_list

        # Get a list of Extension objects from Cython
        source_files = create_extension_list(['**/*.pyx', '**/*.py'])[0]

        # A bug in the latest version of Cython makes it spit out these harmelss warnings; silence those
        for f in source_files:
            f.extra_compile_args = [
                '-Wno-unneeded-internal-declaration',
                '-Wno-unused-function'
            ]

        # Run the regular build_ext command with the Cythonized files
        self.extensions = cythonize(source_files)
        build_ext.run(self)


setup_options = setup(
    name=path.basename(path.realpath(__file__)),
    install_requires=[
        'cython >= 0.23.4',
        'cherrypy >= 4.0.0'
    ],
    cmdclass={
        'clean': CleanCommand,
        'compile': CompileCommand
    }
)

