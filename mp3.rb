require 'net/http'

class String
  alias :oldcmp :<=>
  def <=>(b)
    a = self.lstrip
    b = b.lstrip

    return 0 if (a == "" and b == "")
    return 1 if (a == "")
    return -1 if (b == "")
    return a.oldcmp(b)
  end
end


module Net

  class HTTP
    
    alias :orig_initialize :initialize
   
    # Override HTTP#initialize to set a default @open_timeout to 10 secs. Original
    # initialize method sets @open_timeout to nil, causing connect to wait until 
    # able to open a TCPSocket.
    def initialize(*args)
      orig_initialize(*args)
      @open_timeout ||= 10
    end
    
  end

end

require 'rubygems'
require 'mongrel'
require 'net/daap'
require 'json/pure'
require 'json/add/core'

#$master_albums = []
#$master_artists = []
$master = { "title" => { "asc" => []}, "album" => {}, "artist" => {} }
$master_lock = false
$servers = []
$id = 1
$state_increment = 0

def url_unescape(string)
string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
[$1.delete('%')].pack('H*')
end
end


class SimpleHandler < Mongrel::HttpHandler
	def process(request, response)
		
		response.header['Pragma'] = "no-cache"
		response.header['Cache-control'] = "no-store"
	
=begin
      if( request.params['REQUEST_PATH'] == '/list')
       	response.status = 200
       	response.send_status(nil)
      	response.header["Content-Type"] = "text/plain"
       	response.send_header
       	
       	for s in $master["artist"]["asc"][0..100]
       		response.write("#{s[:serverid]} #{s[:daap].id} -  #{s[:daap].tracknumber} - #{s[:daap].name}\n")
    	end
    	response.done
	  end
=end

      if( request.params['REQUEST_PATH'] == '/break')
      	while 1
      		1+1
  		end
  	  end
	  
	  if( request.params['REQUEST_PATH'] == '/json_query')
	  	get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
	  	puts "#{request.params['REMOTE_ADDR']}: #{get_reqs.inspect}"
	  	t = Time.now
	  	
       	response.status = 200
       	response.send_status(nil)
      	response.header["Content-Type"] = "text/plain"
       	response.send_header
       	
       	master = $master[get_reqs["sort"]][get_reqs["dir"]]
       	
       	if get_reqs['query']
       		q = url_unescape(get_reqs['query']).downcase
       		slist = master.select {|a| a[:daap].name.downcase[q] or (a[:daap].artist.name ? a[:daap].artist.name.downcase[q]: false) or (a[:daap].album.name ? a[:daap].album.name.downcase[q]: false)}
   		else
   			slist = master
   		end
       	   		
   		slist2 = slist[get_reqs["startIndex"].to_i..(get_reqs["startIndex"].to_i+get_reqs["results"].to_i)]
       	json_hsh = { "totalRecords" => slist.length, "recordsReturned" => slist2.length, "startIndex" => 0, "sort" => get_reqs["sort"], "dir" => get_reqs["dir"], "pageSize" => get_reqs["results"], "records" => []}
       	for s in slist2
       		json_hsh["records"] << {"serverid" => s[:serverid], "id" => s[:daap].id, "title" => s[:daap].name, "album" => s[:daap].album.name, "artist" => s[:daap].artist.name }
    	end
    	
    	puts "Render Time: #{(Time.now - t).to_f}"
   
    	response.write(json_hsh.to_json) 	
    	response.done
	  end
	  
	  if(request.params['REQUEST_PATH'] == '/json_status')
	  	puts "#{request.params['REMOTE_ADDR']} J-ST-#{$state_increment}"
	  	response.status = 200
       	response.send_status(nil)
      	response.header["Content-Type"] = "text/plain"
       	response.send_header
       	
       	json_hsh = { "servers" => [], "state_increment" => $state_increment }
       	for s in $servers
       		json_hsh["servers"] << { "id" => s[:id], "name" => s[:name], "count" => s[:count], "address" => s[:address], "ready" => s[:ready] }
   		end
       		
	  	response.write(json_hsh.to_json) 	
    	response.done
  	  end
  	  
  	  if(request.params['REQUEST_PATH'] == '/add')
  	  	puts "#{request.params['REMOTE_ADDR']} Add"
  	  	get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
  	  	
  	  	response.status = 200
       	response.send_status(nil)
      	response.header["Content-Type"] = "text/plain"
       	response.send_header
       	response.done
       	
       	if($master_lock == false)
       		$master_lock = true
       		begin
       			connect(get_reqs["address"], get_reqs["nickname"]);
   			rescue Exception => err
   				puts "ERROR #{err}"
   				$servers.delete($servers.select { |a| a[:ready] == false}[0])
   				$state_increment -= 1
   			end
  	  		$state_increment += 1
  	  		$master_lock = false
  	  	end
  	  end
  	  
  	  if(request.params['REQUEST_PATH'] == '/delete')
  	  	puts "#{request.params['REMOTE_ADDR']} Delete"
  	  	if($master_lock == false)
  	  		$master_lock = true
  	  		get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
  	  	
  	  		disconnect(get_reqs["id"].to_i)
  	  		$state_increment += 1
  	  		$master_lock = false
  	  		#sort()
  	  	end
  	  	
  	  	response.status = 200
       	response.send_status(nil)
      	response.header["Content-Type"] = "text/plain"
       	response.send_header
       	response.done
  	  end
	 
	  if( request.params['REQUEST_PATH'] == '/get')
       	response.status = 200
       	response.send_status(nil)
	  	response.header["Content-Type"] = "audio/mpeg"
	  	       	
       	get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
       	
       	s = $master["title"]["asc"].select { |a| a[:serverid] == get_reqs["serverid"].to_i and a[:daap].id == get_reqs["id"].to_i }.first
       	if s.nil?
       		puts "Bad Request: #{get_reqs.inspect}"
   		end
   		
       	puts "#{request.params['REMOTE_ADDR']} Starting stream of #{s[:daap].name}"
       	s[:daap].get2 do |res|
       		response.header["Content-Length"] = res["CONTENT-LENGTH"]
       		response.send_header
       		
       		res.read_body { |data| response.write(data) }
        end
           	
       	puts "Ending stream of #{s[:daap].name}"
       	response.done
	  end
    end
end

def connect(address, name, initial=false)
	puts "Starting fetch for #{address}"
	if(initial)
		work = $master
	else
		work = { "title" => { "asc" => $master["title"]["asc"].dup }, "album" => {}, "artist" => {} }
	end
	
	daap = Net::DAAP::Client.new(address)
	hsh = {:address => address, :name => name, :id=>$id, :count => "", :ready => false }
	$servers << hsh
	
	daap.connect
	
	i = 0
	daap.databases.each do |db|
		i += db.songs.length
		work["title"]["asc"] += db.songs.map! {|a| {:serverid => $id, :daap => a} }
		#$master_artists += db.artists.map! {|a| {:serverid => $id, :daap => a} }
		#$master_albums += db.albums.map! {|a| {:serverid => $id, :daap => a} }
	end
	
	hsh[:count] = i
	$id += 1
	puts "Finished fetch for #{address}"
	if(initial == false)
		sort(work)
		hsh[:ready] = true
	else
		hsh[:ready] = true
	end
	$master = work
end

def disconnect(id)
	puts id
	s = $servers.select { |a| a[:id] == id}[0]
	$servers.delete(s)
	
	$master.each_value { |a| a.each_value { |b| b.delete_if { |c| c[:serverid] == id } } }
	puts "#{s} disconnected"
end

def sort_artist(arr, desc)
	arr.sort! do |a,b|
		if(desc)
			res = (b[:daap].artist.name ? b[:daap].artist.name : "") <=> (a[:daap].artist.name ? a[:daap].artist.name : "")
		else
			res = (a[:daap].artist.name ? a[:daap].artist.name : "") <=> (b[:daap].artist.name ? b[:daap].artist.name : "")
		end
		if(res == 0)
			res = (a[:daap].album.name ? a[:daap].album.name : "") <=> (b[:daap].album.name ? b[:daap].album.name : "")
			if (res == 0)
				res = (a[:daap].tracknumber ? a[:daap].tracknumber.to_i : 0) <=> (b[:daap].tracknumber ? b[:daap].tracknumber.to_i : 0) 
			end
		end
		res
	end
end
	
def sort_album(arr, desc)
	arr.sort! do |a,b|  
		if(desc)
			res = (b[:daap].album.name ? b[:daap].album.name : "") <=> (a[:daap].album.name ? a[:daap].album.name : "")
		else
			res = (a[:daap].album.name ? a[:daap].album.name : "") <=> (b[:daap].album.name ? b[:daap].album.name : "") 
		end
		if(res == 0)
			res = (a[:daap].tracknumber ? a[:daap].tracknumber.to_i : 0)  <=> (b[:daap].tracknumber ? b[:daap].tracknumber.to_i : 0)
		end
		res
	end
end

def sort_title(arr, desc)
	arr.sort! do |a,b|  
		if(desc)
			res = b[:daap].name <=> a[:daap].name 
		else
			res = a[:daap].name <=> b[:daap].name 
		end
		res
	end
end
def sort(mstr)
	puts "Running sorts"
	mstr["album"]["asc"] = mstr["title"]["asc"].dup
	mstr["album"]["desc"] = mstr["title"]["asc"].dup
	mstr["artist"]["asc"] = mstr["title"]["asc"].dup
	mstr["artist"]["desc"] = mstr["title"]["asc"].dup
	mstr["title"]["desc"] = mstr["title"]["asc"].dup

	sort_album(mstr["album"]["asc"], false)
	sort_album(mstr["album"]["desc"], true)
	sort_artist(mstr["artist"]["asc"], false)
	sort_artist(mstr["artist"]["desc"], true)
	sort_title(mstr["title"]["asc"], false)
	sort_title(mstr["title"]["desc"], true)
	puts "Finished sorts"
end


#for s in [['localhost', 'mileswu']]#,['86.150.102.214', 'zetetic']]#, 'licht.stupidpupil.co.uk']
#	connect(s[0],s[1],true)
#end

sort($master)

h = Mongrel::HttpServer.new("0.0.0.0", "3001")
h.register("/", SimpleHandler.new)
h.register("/html", Mongrel::DirHandler.new("."))
h.register("/datum", Mongrel::DirHandler.new("/mnt/raid/Music"))
puts "Listening"
h.run.join
