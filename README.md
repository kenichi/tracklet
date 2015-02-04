Tracklet
========

Tracklet is an open source iOS app and webservice for tracking and storing your own
location. The iOS app requires version 8 or higher and includes support for monitoring
visits ("frequent locations" or [CLVisit](https://developer.apple.com/library/prerelease/ios/documentation/CoreLocation/Reference/CLVisit_class/index.html)).

The webservice includes a bootstrap-based [Mapbox](https://mapbox.com) view with
support for streaming updates as they arrive at the server, via WebSocket or
EventSource. The view allows the user to "step" through locations and/or visits
with a slider.

The iOS app is *very* basic and includes no map views, yet. *wink* Look for UDP
streaming upload soon!

Just barely a start, hopefully more to come. This project is definitely
looking for contributors!

### Getting Started

The source is divided into two trees:

* /ios - Tracklet iOS app
* /web - Tracklet ruby webservice

#### Webservice

I would have liked to have a "Heroku Button" here, but PostGIS support on Heroku is minimum $50/mo. So,
here are basic instructions for running on your own infrastructure.

Host requirements:

* postgresql >= 9.2 w/ postgis >= 2.1
* redis
* ruby >= 2.1

Steps to get it running after installing prerequisites:

1. `cd tracklet/web`
2. `bundle install`
3. `cp config.yml.template config.yml` and edit config.yml
4. `rake -T` will show you available rake tasks
5. `rake db` will drop/create/migrate database (make sure config.yml[:db][:url] is set!)
6. `bin/tracklet` or `rake web` will run the service

Ideally, you should run this behind a proxy that has SSL configured. Here is a sample
ngnix (non-SSL) configuration:

```
server {
    listen 12.34.56.78:80;
    server_name example.com;

    # make nginx serve "public" files
    #
    root /path/to/tracklet/web/public;
    location / {
      try_files $uri @tracklet;
    }

    location @tracklet {

        # adjust for your config
        #
        proxy_pass http://localhost:4567;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;

        # websocket proxy support
        #
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }
}
```

#### iOS app

1. open `tracklet/iOS/Tracklet.xcodeproj`
2. edit `NetworkManager.m`
3. change `BaseUrl` to where you are running your tracklet webservice
4. connect your iPhone, select it as a destination, and run!

Inside the app, switches turn on and off location and visit monitoring.

Tapping the "Locations to upload" or "Visits to upload" cell triggers
upload.

Tapping the "Locations uploaded" or "Visits uploaded" cell removes uploaded
Locations or Visits.

Locations and Visits are stored in CoreData until they are removed. Upload
times are stored upon succesful upload.

### License

see LICENSE file.
No warranty whatsoever.
