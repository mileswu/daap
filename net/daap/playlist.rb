module Net
  module DAAP
# This class contains information about playlists returned from the iTunes
# server.
    class Playlist
      attr_reader :itemcount, :persistentid, :name, :id

      def initialize(args)
        @itemcount      = args['dmap.itemcount']
        @persistentid   = args['dmap.persistentid']
        @name           = args['dmap.itemname']
        @id             = args['dmap.itemid']
        @daap           = args[:daap]
        @db             = args[:db]
      end

# Returns a list of songs associated with this playlist.
      def songs
        path = "databases/#{@db.id}/containers/#{@id}/items?type=music&meta=dmap.itemkind,dmap.itemid,dmap.containeritemid"
        result = @daap.do_get(path)
        listings = @daap.dmap.find(result,
                            "daap.playlistsongs/dmap.listing")
        songs = []
        @daap.unpack_listing(listings) do |value|
          if block_given?
            yield @db.songs.find { |s| s.id == value['dmap.itemid'] }
          else
            songs << @db.songs.find { |s| s.id == value['dmap.itemid'] }
          end
        end
        songs
      end
    end
  end
end
