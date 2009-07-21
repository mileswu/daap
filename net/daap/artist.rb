module Net
  module DAAP
# This class contains artist information returned from the DAAP server.
    class Artist
      include Comparable
      attr_reader :name, :albums, :songs

      alias :to_s :name

      def initialize(args)
        @name   = args[:name] || args['daap.songartist']
        @albums = []
        @songs  = []
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end
end
