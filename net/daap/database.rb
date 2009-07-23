class Module
  def attr_blockreader(*syms)
    syms.each do |sym|
      class_eval %{ def #{sym.to_s}
                      if block_given?
                        @#{sym.to_s}.each \{ |s| yield s \}
                      end
                      @#{sym.to_s}
                    end
                  }
    end
  end
end

module Net
  module DAAP
# This class contains a database found on an iTunes server.
    class Database
      attr_reader :persistentid, :name, :containercount, :id, :itemcount
      attr_blockreader :songs, :artists, :albums

      @@SONG_ATTRIBUTES = %w{ dmap.itemid dmap.itemname dmap.persistentid
                             daap.songalbum daap.songartist daap.songformat
                                                            daap.songsize daap.songtracknumber } #mileswu

      def initialize(args)
        @persistentid   = args['dmap.persistentid']
        @name           = args['dmap.itemname']
        @containercount = args['dmap.containercount']
        @id             = args['dmap.itemid']
        @itemcount      = args['dmap.itemcount']
        @daap           = args[:daap]
        @songs          = []
        @artists        = []
        @albums         = []
        load_songs
      end

# Returns the playlists associated with this database
      def playlists
        url = "databases/#{@id}/containers?meta=dmap.itemid,dmap.itemname,dmap.persistentid,com.apple.itunes.smart-playlist"
        res = @daap.do_get(url)

        listings = @daap.dmap.find(res, "daap.databaseplaylists/dmap.listing")

        playlists = []
        @daap.unpack_listing(listings) do |value|
          playlist = Playlist.new( value.merge( 
                                    :daap     => @daap,
                                    :db       => self ))
          if block_given?
            yield playlist
          else
            playlists << playlist
          end
        end
        playlists
      end

      private
      def load_songs
        path = "databases/#{@id}/items?type=music&meta="
        path += @@SONG_ATTRIBUTES.join(',')
		
        d1 = @daap.do_get(path) #mileswu
        d2 = d1.dup
        listings = @daap.dmap.find(d1,
                             "daap.databasesongs/dmap.listing")
        if (listings == nil)
        	listings = @daap.dmap.find(d2, "daap.returndatabasesongs/dmap.listing")
        	puts "DMAP/DAAP PROBLEM!!!!!" if( listings == nil)
    	end
        	
        artist_hash = {}
        album_hash  = {}
                
        @daap.unpack_listing(listings) do |value|
          artist  = artist_hash[value['daap.songartist']] ||= Artist.new(value)
          album   = album_hash[value['daap.songalbum']]   ||= Album.new(
                              :name   => value['daap.songalbum'],
                              :artist => artist )

          song = Song.new(  value.merge(
                            :daap      => @daap,
                            :db        => self,
                            :artist    => artist,
                            :album     => album))

          album.songs   << song
          artist.songs  << song
          @songs        << song
        end

        # Add each album to its artist
        album_hash.each_value do |value|
          value.artist.albums << value
          @albums << value
        end

        artist_hash.each_value { |v| @artists << v }
      end
    end
  end
end
