# -*- coding: utf-8 -*-
import dash
import dash_core_components as dcc
import dash_html_components as html
import pandas as pd
import overpy

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']

mapbox_access_token = 'pk.eyJ1IjoiYWxpc2hvYmVpcmkiLCJhIjoiY2ozYnM3YTUxMDAxeDMzcGNjbmZyMmplZiJ9.ZjmQ0C2MNs1AzEBC_Syadg'

app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

myApi = overpy.Overpass()
ice_creams = myApi.query("""node["addr:city"="Bielefeld"]["amenity"="ice_cream"];out body;""")
kindergardens = myApi.query("""node["addr:city"="Bielefeld"]["amenity"="kindergarten"];out body;""")
ice_dict= {"lat":[ice.lat for ice in ice_creams.nodes],
           "lon":[ice.lon for ice in ice_creams.nodes],
           "name":[ice.tags["name"] for ice in ice_creams.nodes],
           "strasse":[ice.tags["addr:street"] for ice in ice_creams.nodes],
           "nr":[ice.tags["addr:housenumber"] for ice in ice_creams.nodes],
           "stadt":[ice.tags["addr:city"] for ice in ice_creams.nodes]}
kg_dict= {"lat":[kg.lat for kg in kindergardens.nodes],
           "lon":[kg.lon for kg in kindergardens.nodes],
           "name":["Kindergarten",] * len(kindergardens.nodes),
           "strasse":[kg.tags["addr:street"] for kg in kindergardens.nodes],
           "nr":[kg.tags["addr:housenumber"] for kg in kindergardens.nodes],
           "stadt":[kg.tags["addr:city"] for kg in kindergardens.nodes]}
df_ice = pd.DataFrame(ice_dict)
df_kg = pd.DataFrame(kg_dict)

app.layout = html.Div(children=[
    html.H1(children='Hello Dash'),

    html.Div(children='''
        Dash: An example without a use yet!
    '''),

    dcc.Graph(id='map', figure={
        'data': [{
            'lat': df_ice['lat'],
            'lon': df_ice['lon'],
            'marker': {
                'color': "red",
                'size': 8,
                'opacity': 0.6
            },
            'text': df_ice['name'],
            'customdata': df_ice['name'],
            'type': 'scattermapbox'
        }] +  [{
            'lat': df_kg['lat'],
            'lon': df_kg['lon'],
            'marker': {
                'color': "blue",
                'size': 8,
                'opacity': 0.6
            },
            'text': df_kg['name'],
            'customdata': df_kg['name'],
            'type': 'scattermapbox'
        }],
        'layout': {
            'mapbox': {
                'accesstoken': 'pk.eyJ1IjoiY2hyaWRkeXAiLCJhIjoiY2ozcGI1MTZ3MDBpcTJ3cXR4b3owdDQwaCJ9.8jpMunbKjdq1anXwU5gxIw',
                'center' : {"lat": 52.022915, "lon": 8.528429},
                'zoom' : 9,
            },
            'hovermode': 'closest',
            'margin': {'l': 0, 'r': 0, 'b': 0, 't': 0}
        }
    }),

    dcc.Graph(
        id='example-graph',
        figure={
            'data': [
                {'x': [1, 2, 3], 'y': [4, 1, 2], 'type': 'bar', 'name': 'SF'},
                {'x': [1, 2, 3], 'y': [2, 4, 5], 'type': 'bar', 'name': u'Montréal'},
            ],
            'layout': {
                'title': 'Dash Data Visualization'
            }
        }
    ),
])

if __name__ == '__main__':
    app.run_server(debug=True, port=5050)
