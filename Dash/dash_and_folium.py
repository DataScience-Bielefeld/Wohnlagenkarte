import folium
import pandas as pd
import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
import overpy

NY_COORDINATES =(52.022915, 8.528429)

my_map = folium.Map(location=NY_COORDINATES, tiles= "Stamen Toner", zoom_start=12)

# BB Bielefeld: node(51.58094, 8.25457, 52.03187, 8.37570);
myApi = overpy.Overpass()
ice_creams = myApi.query("""node["addr:city"="Bielefeld"]["amenity"="ice_cream"];out body;""")
kindergardens = myApi.query("""node["addr:city"="Bielefeld"]["amenity"="kindergarten"];out body;""")
print(len(ice_creams.nodes))

#tags = {'addr:city': 'Bielefeld', 'addr:country': 'DE', 'addr:housenumber': '38', 'addr:postcode': '33615', 'addr:street': 'Stapenhorststraße', 'amenity': 'ice_cream', 'food': 'yes', 'indoor_seating': 'yes', 'internet_access': 'no', 'name': 'Eiscafe Venezia', 'note:de': 'im Winter geschlossen', 'opening_hours': 'Mo-Sa 10:00-22:00; Su 11:00-22:00', 'outdoor_seating': 'yes', 'toilets:wheelchair': 'no', 'wheelchair': 'yes', 'wheelchair:description': 'alles ebenerdig, aber Toilette sehr eng ...'}

ice_cream_markers = [folium.Marker([ice.lat, ice.lon], popup='Eisdiele', tooltip=r"""<p>{name}<br/>{strasse} {nr}<br/>{stadt}</p>"""
                           .format(name=ice.tags["name"],strasse=ice.tags["addr:street"],
                                   nr=ice.tags["addr:housenumber"],stadt=ice.tags["addr:city"])).add_to(my_map) for ice in ice_creams.nodes]
kindergarden_markers = [folium.Marker([kg.lat, kg.lon], popup='Kindergarten', tooltip=r"""<p>Kindergarten<br/>{strasse} {nr}<br/>{stadt}</p>"""
                           .format(strasse=kg.tags["addr:street"],
                                   nr=kg.tags["addr:housenumber"],stadt=kg.tags["addr:city"]), icon=folium.Icon(color='red')).add_to(my_map) for kg in kindergardens.nodes]
my_map.save("NYC_map.html")

app = dash.Dash(__name__)

app.layout = html.Div([
    html.H1("Bielefeld City Map"),
    html.Iframe(id = "map", srcDoc=open("NYC_map.html", "r").read(), width="100%", height="600")
])

if __name__ == '__main__':
    app.run_server(debug=True)