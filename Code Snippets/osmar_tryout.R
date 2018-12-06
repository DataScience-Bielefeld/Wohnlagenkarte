library(osmar)

# osmsource_api()$url

# Bielefeld
bb<-center_bbox(center_lon=8.532368, center_lat=52.030546, width=1800, height=1800)

# Bielefeld
#center_lon=8.532368, center_lat=52.030546
# jöllenbeck 52.100618, 8.517948
# brake 52.071980, 8.614937
# owd/a33 51.976492, 8.472801
# autobahnkreuz 51.944335, 8.542496

api <- osmsource_api()
src <- osmsource_api(url = "https://api.openstreetmap.org/api/0.6/")
bielefeld<-get_osm(bb, source=src)

# der fehler mit https und http ist in Doku von osmar noch nicht korrigiert worden

bielefeld$nodes$attrs[1:6,]

# Alle Tags, die verwendet werden
levels(bielefeld$nodes$tags)

###################
# Try Out OSRM
# https://cmhh.github.io/post/routing/

library(rjson)

### Driving
o <- data.frame("lat" = 52.022783 , "lng" = 8.529823) # Ritterstraße Bielefeld
d <- data.frame("lat" = 52.013414 , "lng" = 8.531711) # Lessingstraße Bielefeld

(url <- paste0("http://router.project-osrm.org/route/v1/driving/", 
               o$lng,",",o$lat,";",d$lng,",",d$lat,"?overview=false"))
route <- fromJSON(file=url)
#--> eigenen 
if(route$code == "Ok")
  route$routes[[1]]$duration #(Minuten)
  route$routes[[1]]$distance #(Meter)

### Walking

  url.walk <- paste0("http://router.project-osrm.org/route/v1/foot/", 
                 o$lng,",",o$lat,";",d$lng,",",d$lat,"?overview=false")
  route.walk <- fromJSON(file=url.walk)
  #--> eigenen 
  if(route.walk$code == "Ok")
    route.walk$routes[[1]]$duration #(Minuten)
  route.walk$routes[[1]]$distance #(Meter)

### Cycling
  
  (url.cycl <- paste0("http://router.project-osrm.org/route/v1/bike/", 
                      o$lng,",",o$lat,";",d$lng,",",d$lat,"?overview=false"))
  route.cycl <- fromJSON(file=url.cycl)
  #--> eigenen 
  if(route.cycl$code == "Ok")
    route.cycl$routes[[1]]$duration #(Minuten)
  route.cycl$routes[[1]]$distance #(Meter)
  