module Net
  module DAAP
# This class contains album information returned from the DAAP server.
    class Album
      include Comparable
      attr_reader :name, :artist, :songs

      alias :to_s :name

      def initialize(args)
        @name   = args[:name] || args['daap.songalbum']
        @artist = args[:artist]
        @songs  = []
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end
end
