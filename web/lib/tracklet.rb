require 'bundler'
Bundler.require
require 'yaml'

module Tracklet

  LOCATION_ATTRS = [
    :longitude,
    :latitude,
    :horizontal_accuracy,
    :vertical_accuracy,
    :altitude,
    :speed,
    :course,
    :timestamp
  ]

  VISIT_ATTRS = [
    :longitude,
    :latitude,
    :horizontal_accuracy,
    :arrival_date,
    :departure_date
  ]

  CONFIG_FILE = File.expand_path '../../config.yml', __FILE__
  begin
    CONFIG = YAML.load_file CONFIG_FILE
  rescue => e
    STDERR.puts "unable to read: #{CONFIG_FILE}"
    exit 1
  end

  CHANNEL = CONFIG[:channel]
  REDIS = Redis.new driver: :celluloid
  DB = Sequel.connect CONFIG[:db][:url]
  Sequel.default_timezone = :utc

end

# don't hate
class Symbol
  def method_missing meth, *args
    if self == :st
      Sequel.function "st_#{meth}", *args
    else
      super
    end
  end
end

# todo move it somewhere
module Terraformer
  class Point

    DEFAULT_RANDOM_POINTS = 10
    DEFAULT_RANDOM_DELTA = 0.05 # degrees
    DEFAULT_RANDOM_ROUND = 5

    def random_points n = DEFAULT_RANDOM_POINTS,
                      delta = DEFAULT_RANDOM_DELTA,
                      round = DEFAULT_RANDOM_ROUND
      s = ->{rand(2) * 2 - 1} # -1 or 1
      Array.new(n) do
        x = (coordinates.x + s[] * rand() * delta).round(round)
        y = (coordinates.y + s[] * rand() * delta).round(round)
        Terraformer::Point.new x, y
      end
    end

    def to_location_hash haccuracy: 5,
                         vaccuracy: 5,
                         altitude: 0,
                         speed: 0,
                         course: 0,
                         timestamp: Time.now.utc
      { longitude: coordinates.x,
        latitude: coordinates.y,
        horizontal_accuracy: haccuracy,
        vertical_accuracy: vaccuracy,
        altitude: altitude,
        speed: speed,
        course: course,
        timestamp: timestamp }
    end

    def to_visit_hash haccuracy: 5, arrival: true
      { longitude: coordinates.x,
        latitude: coordinates.y,
        horizontal_accuracy: haccuracy,
        created_at: Time.now.utc,
        (arrival ? :arrival_date : :departure_date) => Time.now.utc }
    end
  end
end

$:.unshift File.expand_path('..', __FILE__)
require 'tracklet/base'
