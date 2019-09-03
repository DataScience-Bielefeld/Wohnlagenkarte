import plotly.plotly as plotly
import plotly.graph_objs as graph_objs
import dash
import dash_html_components as html
import overpy

BI_COORDINATES =(52.022915, 8.528429)

myApi = overpy.Overpass()
ice_creams = myApi.query("""node["addr:city"="Bielefeld"]["amenity"="ice_cream"];out body;""")


print(len(ice_creams.nodes))

# The solution on the web, which we used here uses mapbox. But mapbox requires a token
# for which we would need to pay a fee. We are currently looking for a mapbox-free solution
# but have not found any solution which uses plotly and does not use mapbox.
layout = graph_objs.Layout(
    height=600,
    autosize = True,
    mapbox=dict(accesstoken="", bearing=0, center=BI_COORDINATES, pitch=0, zoom=5.2, style="light")
)

app = dash.Dash(__name__)

# Once we got that actual plot/layout working, we would need to include this into our app. The code
# as it is here, is still from the folium-based solution.
app.layout = html.Div([
    html.H1("Bielefeld City Map"),
    html.Iframe(id = "map", srcDoc=open("NYC_map.html", "r").read(), width="100%", height="600")
])

if __name__ == '__main__':
    app.run_server(debug=True)
