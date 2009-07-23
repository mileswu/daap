require 'net/http'
require 'digest/m4p'
require 'digest/md5'
require 'net/daap/dmap'
require 'net/daap/artist'
require 'net/daap/album'
require 'net/daap/song'
require 'net/daap/playlist'
require 'net/daap/database'
require 'net/daap/daap_version'
require 'net/daap/speed_hacks'


module Net
# = Synopsis
# The DAAP library is used for browsing an iTunes share.
# Make sure that Digest::M4P is installed before using this library.
#
# == Example
#  require 'rubygems'
#  require 'net/daap'
#
#  daap = Net::DAAP::Client.new('localhost')
#  daap.connect do |dsn|
#
#   daap.databases do |db|
#    puts "All songs in the database"
#    db.songs do |song|
#      puts "#{song.artist} - #{song.name}"
#    end
#
#    puts "Songs for each playlist"
#    db.playlists do |pl|
#      puts "Playlist name: #{pl.name}"
#      pl.songs do |song|
#        puts "#{song.artist} - #{song.name}"
#        File::open("dl/#{song.artist} - #{song.name}.#{song.format}", "w") do |f|
#          f << song.get
#        end
#      end
#    end
#   end
#  end
#
  module DAAP
    VERSION = '0.2.3'

# = Synopsis
# The Client class interacts with the iTunes server to fetch lists of songs,
# databases, and playlists.  Each Client class can have many Database,
# and each Database can have many Playlist, and many Song.  See DAAP for a
# code example.
class MyLog
	def method_missing(arg, str)
		puts str
	end
end

    class Client
      attr_accessor :log
      attr_reader :dmap

# Create a new Client and pass in the host where the client will connect.
      def initialize(server_host, parameters = {})
        params = { :port => 3689, :password => nil }.merge(parameters)
        @server_host = server_host
        @server_port = params[:port]
        @password    = params[:password]
        @validator   = nil
        @log         = nil #MyLog.new
        @session_id  = nil
        @request_id  = nil
        @connected   = false
        yield self if block_given?
      end

# Connects to the iTunes server.  This method should be called right after
# construction.  See DAAP for an example.
      def connect
        log.info("Connecting to #{@server_host}:#{@server_port}") if log
        @http_client = Net::HTTP.start(@server_host, @server_port)
        @http_client.open_timeout = 15 #mileswu

        find_validator
        @dmap = Net::DAAP::DMAP.new(:daap => self)
        load_server_info
        log.info("Now connected") if log
        @connected = true
        if block_given?
          yield @dsn
          disconnect
        end
        @dsn
      end

      # Connect to the server and yield each database to the caller, then
      # automatically disconnect from the server.
      def connect_db(&block)
        raise ArgumentError if block.nil?
        connect
        begin
          databases.each { |db| block.call(db) }
        ensure
          disconnect
        end
      end

# Returns the databases found on the iTunes server.
      def databases
        unless @connected
          errstr = "Not connected, can't fetch databases"
          log.error(errstr) if log
          raise errstr
        end

        listings = @dmap.find(do_get("databases"),
                            "daap.serverdatabases/dmap.listing")
        # FIXME check the value of listing
        @databases = []
        unpack_listing(listings) do |value|
          db = Database.new( value.merge(:daap => self) )
          if block_given?
            yield db
          else
            @databases << db
          end
        end
        @databases
      end

      def do_get(request, &block)
        log.debug("do_get called") if log
        url = String.new('/' + request)
        if @session_id
          url += url =~ /\?/ ?  "&" : "?"
          url += "session-id=#{@session_id}"
        end

        #if @revision && request != "logout"
        #  url += "&revision-number=#{@revision}"
        #end
        log.debug("Fetching url: #{url}") if log

        req = Net::HTTP::Get.new(url, request_headers(url))
        req.basic_auth('iTunes_4.6', @password) if ! @password.nil?
        http_client = Net::HTTP.start(@server_host, @server_port) #mileswu
        http_client.open_timeout = 15 #mileswu
        res = http_client.request(req) do |response|
          response.read_body(&block)
        end

        case res
        when Net::HTTPSuccess
        else
          log.error("This DAAP Server requires a password") if log
          res.error!
        end

        log.debug("Done Fetching url: #{url}") if log

        content_type = res.header['content-type']
        if request !~ /(?:\/items\/\d+\.|logout)/ && content_type !~ /dmap/
          raise "Broken response"
        end

        res.body
      end
      
      def do_get2(request, &block)
        log.debug("do_get called") if log
        url = String.new('/' + request)
        if @session_id
          url += url =~ /\?/ ?  "&" : "?"
          url += "session-id=#{@session_id}"
        end

        #if @revision && request != "logout"
        #  url += "&revision-number=#{@revision}"
        #end
        log.debug("Fetching url: #{url}") if log

        req = Net::HTTP::Get.new(url, request_headers(url))
        req.basic_auth('iTunes_4.6', @password) if ! @password.nil?
        http_client = Net::HTTP.start(@server_host, @server_port) #mileswu
        res = http_client.request(req, &block)

        case res
        when Net::HTTPSuccess
        else
          log.error("This DAAP Server requires a password") if log
          res.error!
        end

        log.debug("Done Fetching url: #{url}") if log

        content_type = res.header['content-type']
        if request !~ /(?:\/items\/\d+\.|logout)/ && content_type !~ /dmap/
          raise "Broken response"
        end

        res.body
      end

      def get_song(request, &block)
        log.debug("Downloading a song") if log
        @request_id = @request_id.nil? ? 2 : @request_id + 1
        do_get(request, &block)
      end
      
      def get_song2(request, &block)
        log.debug("Downloading a song") if log
        @request_id = @request_id.nil? ? 2 : @request_id + 1
        do_get2(request, &block)
      end

      def unpack_listing(listing, &func)
        listing.each do |item|
          record = Hash.new
          item[1].each do |pair_ref|
            record[pair_ref[0]] = pair_ref[1]
          end
          yield record
        end
      end

# Disconnects from the DAAP server
      def disconnect
        log.info("Disconnecting") if log
        do_get("logout")
        @connected = false
      end

      private
      def load_server_info
        flat_list = @dmap.flat_list(do_get("server-info"))
        @dsn = flat_list['/dmap.serverinforesponse/dmap.itemname']

        log.debug("Connected to share '#{@dsn}'") if log
        @session_id = @dmap.find(do_get("login"),
                "dmap.loginresponse/dmap.sessionid")
        log.debug("My id is #{@session_id}") if log
        @dsn
      end

      def request_headers(url)
        headers = Hash.new
        headers['Client-DAAP-Version'] = "3.0"
        headers['Client-DAAP-Access-Index'] = "2"
        headers['Client-DAAP-Request-ID'] = @request_id.to_s if @request_id
        headers['Client-DAAP-Validation'] =
            @validator.validate(url, 2, @request_id) if @validator

        headers
      end

      # Figure out what protocol version to use
      def find_validator
        log.info("Determining DAAP version") if log
        res = @http_client.get('/server-info')
        server = res.header['daap-server']

        if server =~ /^iTunes\/4.2/
          @validator = DAAPv2.new
          log.info("Found DAAPv2") if log
        end

        if server =~ /^iTunes/
          @validator = DAAPv3.new
          log.info("Found DAAPv3") if log
        end
      end
    end

# This class is used for generating a Client-DAAP-Validation header for iTunes
# version 4.2 servers.
    class DAAPv2
      def initialize
        @seeds = []
        (0..255).each do |i|
          string = String.new
          string += (i & 0x80) != 0 ? "Accept-Language"     : "user-agent"
          string += (i & 0x40) != 0 ? "max-age"             : "Authorization"
          string += (i & 0x20) != 0 ? "Client-DAAP-Version" : "Accept-Encoding"
          string += (i & 0x10) != 0 ? "daap.protocolversion": "daap.songartist"
          string += (i & 0x08) != 0 ? "daap.songcomposer"   : "daap.songdatemodified"
          string += (i & 0x04) != 0 ? "daap.songdiscnumber" : "daap.songdisabled"
          string += (i & 0x02) != 0 ? "playlist-item-spec"  : "revision-number"
          string += (i & 0x01) != 0 ? "session-id"          : "content-codes"
          @seeds << Digest::MD5.new(string).to_s.upcase
        end
      end
# Returns a validation header based on MD5
      def validate(path, select = 2, req_id = nil)
        string = path.dup
        string += "Copyright 2003 Apple Computer, Inc."
        string += @seeds[select]
        return Digest::MD5.new(string).to_s.upcase
      end
    end

# This class is used for generating a Client-DAAP-Validation header for iTunes
# servers newer than 4.2, or something.
    class DAAPv3
      attr_reader :seeds
      def initialize
        @seeds = []
        (0..255).each do |i|
          string = String.new
          string += (i & 0x40) != 0 ? "eqwsdxcqwesdc"      : "op[;lm,piojkmn"
          string += (i & 0x20) != 0 ? "876trfvb 34rtgbvc"  :  "=-0ol.,m3ewrdfv"
          string += (i & 0x10) != 0 ? "87654323e4rgbv " : "1535753690868867974342659792"
          string += (i & 0x08) != 0 ? "Song Name"          : "DAAP-CLIENT-ID:"
          string += (i & 0x04) != 0 ? "111222333444555"    : "4089961010"
          string += (i & 0x02) != 0 ? "playlist-item-spec" : "revision-number"
          string += (i & 0x01) != 0 ? "session-id"         : "content-codes"
          string += (i & 0x80) != 0 ? "IUYHGFDCXWEDFGHN"   : "iuytgfdxwerfghjm" 
          @seeds << Digest::M4P.new(string).to_s.upcase
        end
      end
# Returns a validation header using a custom MD5 called Digest::M4P
      def validate(path, select = 2, req_id = nil)
        string = String.new
        string += path
        string += "Copyright 2003 Apple Computer, Inc."
        string += @seeds[select]
        string += req_id.to_s if req_id != nil
        Digest::M4P.new(string).to_s.upcase
      end
    end
  end
end
