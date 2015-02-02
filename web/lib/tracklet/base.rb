module Tracklet

  TYPE = 'type'
  LOCATION_TYPE = 'location'
  VISIT_TYPE = 'visit'
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

    def insert_prep type, o
      case type
      when :location
        o[:timestamp] = Time.parse(o[:timestamp]).utc
      when :visit
        o[:arrival_date] = Time.parse(o[:arrival_date]).utc if o[:arrival_date]
        o[:departure_date] = Time.parse(o[:departure_date]).utc if o[:departure_date]
      end
      o[:created_at] = Time.now.utc
      o[:point] = :st.makepoint(o[:longitude], o[:latitude])
      o
    end

    def line_string
      sds = DB[:locations]
      sds.select! :point
      sds.order! Sequel.desc :timestamp

      ds = DB[Sequel.as(sds, :point)]
      ds.select! :st.asgeojson :st.makeline :st.geomfromewkb :point
      ls = ds.first[:st_asgeojson]

      ls = ls.nil? ?
        Terraformer::LineString.new([]).to_feature :
        Terraformer.parse(ls).to_feature

      ls.to_json include_bbox: true
    end

    def locations limit
      ds = DB[:locations]
      ds.select! *LOCATION_ATTRS,
                 Sequel.as(:st.asgeojson(:st.buffer(:point, :horizontal_accuracy)), :geometry)
      ds.order! Sequel.desc(:timestamp)
      ds.limit! limit
      ds.all.map! {|l| l.merge! geometry: JSON.parse(l[:geometry])}
    end

    def visits
      ds = DB[:visits]
      ds.select! *VISIT_ATTRS,
                 Sequel.as(:st.asgeojson(:point), :geometry)
      ds.order! Sequel.desc(:arrival_date), Sequel.desc(:departure_date)
      ds.limit! 100
      ds.all.map! {|v| v.merge! geometry: JSON.parse(v[:geometry])}
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

    get '/lineString' do
      line_string
    end

    get '/locations' do
      limit = params[:limit] ? Integer(params[:limit]) : 100
      locations(limit).map! &featurize
    end

    get '/visits' do
      visits.map! &featurize
    end

    post '/location' do
      o = insert_prep :location, attr_params(:location)
      async :insert_location, o
      QUEUED
    end

    post '/locations' do
      ls = params[:locations].map do |l|
        o = attr_params(:location, l)
        insert_prep :location, o
      end
      async :insert_locations, ls
      QUEUED
    end

    post '/visit' do
      o = insert_prep :visit, attr_params(:visit)
      async :insert_visit, o
      QUEUED
    end

    post '/visits' do
      vs = params[:visits].map do |l|
        insert_prep :visit, attr_params(:visit, l)
      end
      async :insert_visits, vs
      QUEUED
    end

    # --- pubsub tasks

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

    task :publish_feature do |type, id|
      ds = DB[(type + 's').to_sym]
      attrs = Tracklet.const_get type.upcase + '_ATTRS'
      case type
      when LOCATION_TYPE
        ds.select! *attrs, Sequel.as(:st.asgeojson(:st.buffer(:point, :horizontal_accuracy)), :geometry)
      when VISIT_TYPE
        ds.select! *attrs, Sequel.as(:st.asgeojson(:point), :geometry)
      end
      ds.filter! id: id
      o = ds.first
      f = Terraformer.parse(o.delete :geometry).to_feature
      f.properties = o.merge! type: type
      REDIS.publish CHANNEL, f.to_json
    end

    # --- database insert tasks

    task :insert_location do |l = {}|
      id = DB[:locations].insert l
      async :publish_feature, LOCATION_TYPE, id
    end

    task :insert_locations do |ls = []|
      ids = []
      DB.transaction {ls.each {|l| ids << DB[:locations].insert(l)}}
      ids.each {|id| async :publish_feature, LOCATION_TYPE, id}
    end

    task :insert_visit do |v = {}|
      id = DB[:visits].insert v
      async :publish_feature, VISIT_TYPE, id
    end

    task :insert_visits do |vs = []|
      ids = []
      DB.transaction {vs.each {|v| ids << DB[:visits].insert(v)}}
      ids.each {|id| async :publish_feature, VISIT_TYPE, id}
    end

  end

end
