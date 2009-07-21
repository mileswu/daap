require 'rubygems'
require 'mongrel'
require 'net/daap'
require 'json/pure'
require 'json/add/core'

#$master_albums = []
#$master_artists = []
$master = { "title" => { "asc" => []}, "album" => {}, "artist" => {} }
$id = 1

def url_unescape(string)
string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
[$1.delete('%')].pack('H*')
end
end


class SimpleHandler < Mongrel::HttpHandler
	def process(request, response)
	
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
	  
	  if( request.params['REQUEST_PATH'] == '/json_query')
	  	get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
	  	puts get_reqs.inspect
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
	  
	  if( request.params['REQUEST_PATH'] == '/get')
       	response.status = 200
       	response.send_status(nil)
	  	response.header["Content-Type"] = "audio/mpeg"
	  	       	
       	get_reqs = request.params['QUERY_STRING'].split("&").map { |a| arr = a.split("="); h = {}; h[arr[0]] = arr[1]; h}.inject({}) {|a,b| a.merge(b)}
       	
       	s = $master["title"]["asc"].select { |a| a[:serverid] == get_reqs["serverid"].to_i and a[:daap].id == get_reqs["id"].to_i }.first
       	if s.nil?
       		puts "Bad Request: #{get_reqs.inspect}"
   		end
   		
       	puts "Starting stream of #{s[:daap].name}"
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

def connect(address)
	daap = Net::DAAP::Client.new(address)
	daap.connect
	daap.databases.each do |db|
		$master["title"]["asc"] += db.songs.map! {|a| {:serverid => $id, :daap => a} }
		#$master_artists += db.artists.map! {|a| {:serverid => $id, :daap => a} }
		#$master_albums += db.albums.map! {|a| {:serverid => $id, :daap => a} }
	end
	$id += 1
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

for s in ['localhost']#, 'licht.stupidpupil.co.uk']
	puts "Starting fetch for #{s}"
	connect(s)
	puts "Finished fetch for #{s}"
end

puts "Running sorts"
$master["album"]["asc"] = $master["title"]["asc"].dup
$master["album"]["desc"] = $master["title"]["asc"].dup
$master["artist"]["asc"] = $master["title"]["asc"].dup
$master["artist"]["desc"] = $master["title"]["asc"].dup
$master["title"]["desc"] = $master["title"]["asc"].dup

sort_album($master["album"]["asc"], false)
sort_album($master["album"]["desc"], true)
sort_artist($master["artist"]["asc"], false)
sort_artist($master["artist"]["desc"], true)
sort_title($master["title"]["asc"], false)
sort_title($master["title"]["desc"], true)

h = Mongrel::HttpServer.new("0.0.0.0", "3000")
h.register("/", SimpleHandler.new)
h.register("/html", Mongrel::DirHandler.new("."))
puts "Listening"
h.run.join
