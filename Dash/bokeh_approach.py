from bokeh.plotting import figure, show, output_notebook
from bokeh.tile_providers import CARTODBPOSITRON
center = (950000,6803000)
delta = 18000
p = figure(x_range=(center[0]-delta,center[0]+delta), y_range=(center[1]-delta,center[1]+delta),
           x_axis_type="mercator", y_axis_type="mercator")

p.add_tile(CARTODBPOSITRON)

show(p)
