# Wohnlagenkarte
Multi-Sprint Projekt zu einer individualisierbaren Wohnlagenkarte von Bielefeld

Wir haben uns ein sprichwörtlich bildliches Projekt ausgesucht:
Wir möchten uns mit der
[offiziellen Wohnlagenkarte](https://stadtplan.bielefeld.de/app/wohnlagenkarte_jeder/#?map=8,467871.05013,5763160.84013,EPSG:25832&amp;layers=wohnlagenkarte_pl,stadtplan_bi&amp;sidebarStatus=closed)
der Stadt Bielefeld beschäftigen, welche im Rahmen der
[Open-Data-Initiative der Stadt](https://open-data.bielefeld.de)
veröffentlicht wurde.

Diese interaktive Karte wollen wir als Vorlage nehmen und für den Nutzer
individualisierbar machen. D.h. wir möchten die Möglichkeit schaffen Präferenzen
einzugeben und diese dann für die Bewertung der Wohlagen in Bielefeld verwenden.
Wenn es jemandem also wichtig ist nah an der Stadtbahn und an Eisdielen zu
wohnen, dann möchten wir dies berücksichtigen können.

Hierfür sind eine Vielzahl an Schritten notwendig, welche wir in mehreren Code-
Springs bearbeiten wollen:

1. Wohnlagenkarte als 2D-Grafik erstellen
2. Karte interaktiv gestalten
3. OpenStreetMap-API abfragen um GPS-Koordinaten von Präferenzen im Stadtgebiet abzufragen
4. Algorithmus bestimmen um Bewertung der Wohngebiete zu erzeugen
5. ...

Das Ergebnis einer jeden Iteration dieses Projektes möchten wir als Web-
Applikation öffentlich verfügbar machen. Hierfür verwenden wir Frameworks
für R und Python, mit welchen auf einfache Weise selbst Web-Applikationen
erzeugt werden können – [Shiny](https://shiny.rstudio.com/) und
[Dash](https://plot.ly/products/dash/).

Wenn ihr mehr Informationen erhalten oder mit uns über dieses Projekt
unterhalten möchtet, so schaut bei dem
[nächsten MeetUp](https://www.datascience-bielefeld.de/?page_id=11) vorbei!

## Aktueller Stand

Eine erste Version der Wohnlagenkarte wurde mit Shiny in R umgesetzt und
befindet sich im entsprechenden Unterordner dieses Repositories.

Als Vorlage haben wir die auf der
[Shiny-Seite verfügbare App *Superzip*](https://shiny.rstudio.com/gallery/superzip-example.html)
verwendet. Die Funktionen der wichtigsten Dokumente sind:

* `prepare_data.R` - Die App verwendet ausschließlich öffentlich verfügbare
  Daten. Diese werden in diesem Skript verarbeitet und haben als Ausgabe die
  SQLite-Dateien des `data`-Ordners - dort abgelegt in komprimierter Form.
* `ui.R` - Stellt die Frontend-Programmierung der App dar.
* `server.R` - Dies ist das Backend-Skript der App. Hier werden insbesondere
  die reaktiven Elemente verwaltet und verarbeitet, welche den User-Input
  steuern und die Karte generieren.

Die einfachste Art diese App lokal auszuführen ist mit
[RStudio](https://www.rstudio.com). Hierfür einfach in das App-Verzeichnis
im Dateiexplorer innerhalb von RStudio navigieren, dieses zum
*Working Directory* machen, die Datei `ui.R` öffnen und auf den Button
*Run App* klicken.
