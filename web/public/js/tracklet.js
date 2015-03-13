var Tracklet = function() {

  L.mapbox.accessToken = trackletConfig.mapbox.access_token;

  var es, ws,
      lineString, lineStringLayer,
      cursor = 0, step = 'locations',
      locations = [], visits = [], items,

      map = L.mapbox.map('map', trackletConfig.mapbox.map_id)
                    .setView([45.5165, -122.6764], 12);

  var styles = {
    lineString: {color: '#000000', opacity: 0.25},
    location:   {color: '#000066', opacity: 0.25},
    visit:      {color: '#660000', opacity: 0.25}
  };

  function init() {
    $.get('line_string', function(json) {
      lineString = json;
      showLineStringLayer(true);
    });

    $.get('locations', function(json) {
      locations = json;
      initItems();
      showLocationLayers();
    });

    $.get('visits', function(json) {
      visits = json;
      showVisitLayers();
    });

    initBindings();

    if (trackletConfig.initStreaming) {
      if (trackletConfig.streamType) {
        switch (trackletConfig.streamType) {
          case 'eventsource':
            break;
          case 'websocket':
            $('#websocket-streaming-radio').click();
            break;
        }
      }
      $('#streaming-checkbox').click();
    }
  }

  function initBindings() {
    bindSliderCheckbox();
    bindStepRadio();
    bindStreamingCheckbox();
  }

  function initSlider() {
    cursor = 0;
    $('#slider').attr({
      disabled: false,
      type: 'range',
      min: 0,
      max: items.length - 1,
      step: 1,
      value: cursor
    });
  }

  function initItems() {
    switch (step) {
      case 'locations':
        items = locations;
        break;
      case 'visits':
        items = visits;
        break;
      case 'chrono':
        items = locations;
        items.push.apply(items, visits);
        items.sort(function(a,b) {
          if      (a.timestamp < b.timestamp) { return -1; }
          else if (a.timestamp > b.timestamp) { return 1;  }
          else                                { return 0;  }
        });
    }
  }

  function initEventSource() {
    if (es = new EventSource('?sse=1')) {
      es.addEventListener('location', function(e) {
        handleLocation(JSON.parse(e.data));
      });
      es.addEventListener('visit', function(e) {
        handleVisit(JSON.parse(e.data));
      });
    }
  }

  function initWebSocket() {
    var wsUrl = (trackletConfig.webSocketSSL ? 'wss://' : 'ws://') +
                trackletConfig.webSocketHost + '/';
    if (ws = new WebSocket(wsUrl)) {
      ws.onmessage = function(m) {
        data = JSON.parse(m.data);
        switch (data.properties.type) {
          case 'location':
            handleLocation(data);
            break;
          case 'visit':
            handleVisit(data);
            break;
        }
      };
    }
  }

  function initWebSocketRadio() {
    $('#websocket-streaming-radio').attr('disabled',
      !(typeof trackletConfig.webSocketHost == 'string')
    );
  }

  // --- handling

    function handleLocation(location) {
      var point = [location.properties.longitude, location.properties.latitude];
      lastEvent(location);
      locations.push(location);
      lineString.geometry.coordinates.push(point);
      showLineStringLayer(false);
      showLocationLayers();
    }

    function handleVisit(visit) {
      lastEvent(visit);
      visits.push(visit);
      showVisitLayers();
    }

  // --- showing

    function showLineStringLayer(fit) {
      if (lineString.hasOwnProperty('properties') && lineString.properties.layer) {
        map.removeLayer(lineString.properties.layer);
        lineString.properties.layer = null;
      }
      if (lineString && lineString.hasOwnProperty('type')) {
        if (fit && lineString.geometry.bbox) {
          var b = lineString.geometry.bbox;
          map.fitBounds([[b[1], b[0]], [b[3], b[2]]]);
        }
        lineString.properties.layer = L.geoJson(lineString, {style: styles.lineString});
        lineString.properties.layer.addTo(map);
      }
    }

    function eachFeature(f, l) {
      var pop = f.properties.type + ': ';
      switch (f.properties.type) {
        case 'Location':
          pop = pop + new Date(f.properties.timestamp);
          break;
        case 'Visit':
          var ad = 'n/a', dd = 'n/a';
          if (f.properties.arrival_date) ad = new Date(f.properties.arrival_date);
          if (f.properties.departure_date) dd = new Date(f.properties.departure_date);
          pop = pop + "<br/>arrival: " + ad + "<br/>depart: " + dd;
          break;
      }
      l.bindPopup(pop);
    }

    function showLocationLayers() {
      $.each(locations, function(_,l) {
        if (l.properties.layer){ map.removeLayer(l.properties.layer); }
        l.properties.layer = L.geoJson(l, {style: styles.location, onEachFeature: eachFeature});
        l.properties.style = styles.location;
        l.properties.layer.addTo(map);
      });
    }

    function showVisitLayers() {
      $.each(visits, function(_,v) {
        if (v.properties.layer) { map.removeLayer(v.properties.layer); }
        v.properties.layer = L.geoJson(v, {style: styles.visit, onEachFeature: eachFeature });
        v.properties.style = styles.visit;
        v.properties.layer.addTo(map);
      });
    }

  // --- bindings

    function bindSliderCheckbox() {
      $('#slider-checkbox').on('change', function(e) {
        if (e.target.checked) {
          initSlider();
          bindSlider();
          $('input[name=step-radio]').attr('disabled', true);
          $('#slider').focus();
          showSelectedItem();
        } else {
          $('input[name=step-radio]').attr('disabled', false);
          deselectItem(cursor);
          unbindSlider();
        }
      });
    }

    function bindStepRadio() {
      $('input[name=step-radio]').on('change', function(e) {
        step = $('input[name=step-radio]:checked').val();
        initItems();
      });
    }

    function bindSlider() {
      $('#slider').on('input', function(e){
        deselectItem(cursor);
        cursor = e.target.valueAsNumber;
        showSelectedItem();
      });
    }

    function unbindSlider() {
      $('#slider').off('input');
      $('#slider').attr('disabled', true);
    }

    function bindStreamingCheckbox() {
      $('#streaming-checkbox').on('change', function(e) {
        if (e.target.checked) {
          $('input[name=streaming-radio]').attr('disabled', true);
          switch ($('input[name=streaming-radio]:checked').val()) {
            case "eventsource":
              initEventSource();
              break;
            case "websocket":
              initWebSocket();
              break;
          }
        } else {
          switch ($('input[name=streaming-radio]:checked').val()) {
            case "eventsource":
              es.close();
              break;
            case "websocket":
              ws.close();
              break;
          }
          $('input[name=streaming-radio]').attr('disabled', false);
        }
      });
    }

  // --- selection

    function showSelectedItem() {
      var i = items[cursor];
      i.properties.layer.setStyle(selectedStyle(i.properties.style));
      map.setView(L.latLng(i.properties.latitude, i.properties.longitude), 16);
      i.properties.layer.openPopup();
    }

    function deselectItem(i) {
      items[i].properties.layer.setStyle(items[i].properties.style);
    }

    function selectedStyle(style) {
      var s = $.extend({}, style);
      s.opacity = 0.75;
      return s;
    }
    
    function lastEvent(e) {
      $('#last-event').html(e.type);
    }

  return {
    lineString:      function(){ return lineString; },
    lineStringLayer: function(){ return lineStringLayer; },
    locations:       function(){ return locations; },
    locationLayers:  function(){ return locationLayers; },
    visits:          function(){ return visits; },
    visitLayers:     function(){ return visitLayers; },
    items:           function(){ return items; },

    eventSource: function(){ return es; },
    webSocket:   function(){ return ws; },

    init: init
  };

}();

Tracklet.init();
