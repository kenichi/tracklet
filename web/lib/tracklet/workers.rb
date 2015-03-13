module Tracklet
  module Workers

    TIMESTAMP = 'timestamp'
    CREATED_AT = 'created_at'
    ARRIVAL_DATE = 'arrival_date'
    DEPARTURE_DATE = 'departure_date'

    class LocationInsert
      include Sidekiq::Worker

      def perform l
        l[TIMESTAMP] = Time.parse(l[TIMESTAMP]).utc
        l[CREATED_AT] = Time.now.utc
        id = DB[:locations].insert l
        GeographyUpdate.perform_async LOCATION_TYPE, id
      end

    end

    class VisitInsert
      include Sidekiq::Worker

      def perform v
        v = Angelo::SymHash.new v
        v[ARRIVAL_DATE] = Time.parse(v[ARRIVAL_DATE]).utc if v[ARRIVAL_DATE]
        v[DEPARTURE_DATE] = Time.parse(v[DEPARTURE_DATE]).utc if v[DEPARTURE_DATE]
        v[CREATED_AT] = Time.now.utc
        id = DB[:visits].insert v
        GeographyUpdate.perform_async VISIT_TYPE, id
      end

    end

    class GeographyUpdate
      include Sidekiq::Worker

      def perform type, id
        DB[(type + 's').to_sym].where(id: id).update point: :st.makepoint(:longitude, :latitude)
        PublishGeoJSON.perform_async type, id
      end

    end

    class PublishGeoJSON
      include Sidekiq::Worker

      def perform type, id
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

    end

  end
end
