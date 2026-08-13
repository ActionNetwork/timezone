# frozen_string_literal: true

require 'timezone/error'

module Timezone
  # Responsible for loading and parsing timezone data from files.
  module Loader
    SOURCE_BIT = 0

    @rules = {} # cache of loaded rules

    class << self
      attr_writer :zone_file_path

      def zone_file_path
        @zone_file_path ||= File.expand_path(File.dirname(__FILE__) + '/../../data')
      end

      def load(name)
        @rules.fetch(name) do
          raise ::Timezone::Error::InvalidZone unless valid?(name)

          @rules[name] = parse_zone_data(get_zone_data(name))
        end
      end

      def names
        @names ||= parse_zone_names
      end

      def valid?(name)
        names.include?(name)
      end

      private

      def parse_zone_names
        files = Dir[File.join(zone_file_path, '**/*')].map do |file|
          next if File.directory?(file)

          file.sub("#{zone_file_path}/", '')
        end

        files.compact
      end

      def parse_zone_data(data)
        rules = []

        data.split("\n").each do |line|
          source, name, dst, offset = line.split(':')
          source = source.to_i
          dst = dst == '1'
          offset = offset.to_i
          source = rules.last[SOURCE_BIT] + source if rules.last
          rules << [source, name, dst, offset]
        end

        rules
      end

      # Retrieve the data from a particular time zone
      def get_zone_data(name)
        File.read(File.join(zone_file_path, name))
      end
    end
  end

end
