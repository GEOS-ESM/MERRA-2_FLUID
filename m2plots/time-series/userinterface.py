import argparse

class UserInterface(object):

    def __init__(self, description):

        self.parser = argparse.ArgumentParser(description=description)

        self.parser.add_argument('var', metavar='variable', type=str,
               help='Variable to be plotted')
        self.parser.add_argument('region', metavar='region', type=str,
               help='Region to be plotted')
        self.parser.add_argument('year', metavar='year', type=int,
               help='Year to be highlighted')
        self.parser.add_argument('month', metavar='month', type=int,
               help='The ending month of the year to be highlighted')
        self.parser.add_argument('stream', metavar='stream', type=str,
               help='The stream type being used to plot: ops|retro')
        self.parser.add_argument('config', metavar='config', type=str,
               help='Name of configuration file')
            
    def get_args(self):

        return self.parser.parse_args()
