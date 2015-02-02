Bundler.require :dev

module Tracklet
  module Test
    P = Terraformer::Point.new -122.6764, 45.5165
    HC = HTTPClient.new
    URL = 'http://127.0.0.1:4567/%s'
    H = {'Content-Type' => 'application/json'}

    module Helpers

      def test_location
        ph = P.random_points(1)[0].to_location_hash
        ap ph
        JSON.parse HC.post(URL % 'location', ph.to_json, H).body
      end

      def test_locations
        ls = {locations: P.random_points(5).map!(&:to_location_hash)}
        JSON.parse HC.post(URL % 'locations', ls.to_json, H).body
      end

      def test_visit haccuracy: 5, arrival: true
        v = P.random_points(1)[0].to_visit_hash haccuracy: haccuracy, arrival: arrival
        ap v
        JSON.parse HC.post(URL % 'visit', v.to_json, H).body
      end

      def test_visits
        vs = {visits: P.random_points(5).map!(&:to_visit_hash)}
        JSON.parse HC.post(URL % 'visits', vs.to_json, H).body
      end

    end

  end
end

include Tracklet::Test::Helpers if $0 == 'irb'
