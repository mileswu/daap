require 'fileutils'

module Net
  module DAAP
# This class contains song information returned from the DAAP server.
    class Song
      include Comparable
      attr_reader :size, :album, :name, :artist, :format, :persistentid, :id, :tracknumber #mileswu
      attr_accessor :path, :file

      alias :to_s :name

      def initialize(args)
      	@tracknumber    = args['daap.songtracknumber'] #mileswu
        @size           = args['daap.songsize']
        @album          = args[:album]
        @name           = args['dmap.itemname']
        #@artist         = args['daap.songartist']
        @artist         = args[:artist]
        @format         = args['daap.songformat']
        @persistentid   = args['dmap.persistentid']
        @id             = args['dmap.itemid']
        @daap           = args[:daap]
        @db             = args[:db]
        @path = [@artist.name, @album.name].collect { |name|
          name.gsub(File::SEPARATOR, '_') unless name.nil?
        }.join(File::SEPARATOR)
        @file = "#{@name.gsub(File::SEPARATOR, '_')}.#{@format}"
      end

# Fetches the song data from the DAAP server and returns it.
      def get(&block)
        filename = "#{@id}.#{@format}"
        @daap.get_song("databases/#{@db.id}/items/#{filename}", &block)
      end
      
      def get2(&block)
      	filename = "#{@id}.#{@format}"
        @daap.get_song2("databases/#{@db.id}/items/#{filename}", &block)
  	  end
  	

      def save(basedir = nil)
        path = "#{basedir}#{File::SEPARATOR}#{@path}"
        FileUtils::mkdir_p(path)
        filename = "#{path}#{File::SEPARATOR}#{@file}"
        File.open(filename, "wb") { |file|
          get do |str|
            file.write str
          end
        }
        @daap.log.debug("Saved #{filename}") if @daap.log
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end
end
