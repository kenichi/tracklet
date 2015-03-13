module Tracklet

  TYPE = 'type'
  QUEUED = {status: :queued}

  class Base < Angelo::Base

    addr CONFIG[:addr]
    port CONFIG[:port]
    public_dir '../../public'
    views_dir '../../views'
    log_level ::Logger::DEBUG
    report_errors!
    reload_templates!
    content_type :json

    @@subscribed = false

    # --- helpers

    def attr_params type, from = params
      Tracklet.const_get(type.to_s.upcase + '_ATTRS').reduce({}){|h,k| h[k] = from[k]; h}
    end

    def line_string
      sds = DB[:locations]
      sds.select! :point
      sds.order! Sequel.desc :timestamp

      ds = DB[Sequel.as(sds, :point)]
      ds.select! :st.asgeojson :st.makeline :st.geomfromewkb :point
      ls = ds.first[:st_asgeojson]
      if ls
        ls = Terraformer.parse(ls).to_feature
        ls.to_json include_bbox: true
      end
    end

    def locations limit
      ds = DB[:locations]
      ds.select! *LOCATION_ATTRS,
                 Sequel.as(:st.asgeojson(:st.buffer(:point, :horizontal_accuracy)), :geometry)
      ds.order! Sequel.desc(:timestamp)
      ds.limit! limit
      ds.all.map! {|l| l.merge! type: 'Location', geometry: JSON.parse(l[:geometry])}
    end

    def visits
      ds = DB[:visits]
      ds.select! *VISIT_ATTRS,
                 Sequel.as(:st.asgeojson(:point), :geometry)
      # ds.order! Sequel.desc(:arrival_date), Sequel.desc(:departure_date)
      ds.where! { created_at > (Time.now - 86400) }
      ds.order! Sequel.desc :created_at
      ds.limit! 100
      ds.all.map! {|v| v.merge! type: 'Visit', geometry: JSON.parse(v[:geometry])}
    end

    def featurize
      @featurize ||= ->(h) {
        f= Terraformer.parse(h.delete :geometry).to_feature
        f.properties = h
        f }
    end

    # --- route handlers

    get '/' do
      if params[:sse]
        eventsource do |es|
          sses << es
          async :subscribe unless @@subscribed
        end
      else
        content_type :html
        @stream = !!params[:stream]
        @stream_type = params[:stream_type]
        erb :index
      end
    end

    websocket '/' do |ws|
      websockets << ws
      ws.on_message do |msg|
        begin
          msg = Angelo::SymHash.new JSON.parse msg
          case msg[:type]
          when LOCATION_TYPE
            o = attr_params :location, msg[:data]
            async :insert_location, o
          when VISIT_TYPE
            async :insert_visit, attr_params(:visit, msg[:data])
          end
        rescue JSON::ParserError => jpe
          debug "ws json error: #{jpe.message}"
        end
      end
      async :subscribe unless @@subscribed
    end

    get '/line_string' do
      line_string or {}
    end

    get '/locations' do
      limit = params[:limit] ? Integer(params[:limit]) : 100
      locations(limit).map! &featurize
    end

    get '/visits' do
      visits.map! &featurize
    end

    post '/location' do
      Workers::LocationInsert.perform_async attr_params(:location)
      QUEUED
    end

    post '/locations' do
      params[:locations].each {|l| Workers::LocationInsert.perform_async attr_params(:location, l)}
      QUEUED
    end

    post '/visit' do
      Workers::VisitInsert.perform_async attr_params(:visit)
      QUEUED
    end

    post '/visits' do
      params[:visits].each {|v| Workers::VisitInsert.perform_async attr_params(:visit, v)}
      QUEUED
    end

    # --- tasks

    task :subscribe do
      @@subscribed = true
      ::Redis.new(driver: :celluloid).subscribe CHANNEL do |on|
        on.message do |chan, m|
          websockets.each {|ws| ws.write m}
          pm = Angelo::SymHash.new JSON.parse(m)
          sses.event pm[:properties][:type].downcase, m
        end
      end
      @@subscribed = false
    end

  end

end
