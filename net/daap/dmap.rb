module Net
  module DAAP
# This class decodes responses from the DAAP server in to useful data 
# structures.
    class DMAP
      def initialize(args)
        @daap           = args[:daap]
        @big_endian     = "Ruby".unpack("i")[0] != 2036495698 ? true : false
        @type_to_unpack = find_type
        update_content_codes
      end

      def find(data, to_find)
        seek(unpack(data), to_find)
      end

      def flat_list(data)
        struct = unpack(data)
        hash_list = Hash.new
        flat_list = flat_list_traverse(struct)
        0.step(flat_list.length - 1, 2) do |i|
          hash_list[flat_list[i]] = flat_list[i + 1]
        end
        hash_list
      end

      private
      def find_type
        types = nil
        if @big_endian
          types = {
            1     => 'c',
            3     => 'S',
            5     => 'L',
            7     => 'Q',
            9     => 'a*',
            10    => 'L',
            11    => 'SS',
            42    => 'a*'
          }
        else
          types = {
            1     => 'c',
            3     => 'n',
            5     => 'N',
            7     => 'Q',
            9     => 'a*',
            10    => 'N',
            11    => 'nn',
            42    => 'a*'
          }
        end
        types
      end

      def update_content_codes
        content_codes = unpack(@daap.do_get("content-codes"))
        mccr = seek(content_codes, "dmap.contentcodesresponse")
        mccr.each do |mdcl_rec|
          next unless mdcl_rec[0] == 'dmap.dictionary'
          name = id = type = nil
          mdcl_rec[1].each do |f|
            id    = f[1] if f[0] == 'dmap.contentcodesnumber'
            name  = f[1] if f[0] == 'dmap.contentcodesname'
            type  = f[1] if f[0] == 'dmap.contentcodestype'
          end
          type = 9  if id == 'mcnm'
          type = 42 if id == 'pfdt'
          @@types[id] = { 'NAME' => name, 'ID' => id, 'TYPE' => type }
        end
      end

      def flat_list_traverse(struct, list = [], prefix = '')
        struct.each do |element|
          0.step(element.length - 1, 2) do |i|
            tag, data = element[i], element[i + 1]
            if data.class == Array
              flat_list_traverse(data, list, "#{prefix}/#{tag}")
            else
              list << "#{prefix}/#{tag}"
              list << data
            end
          end
        end
        list
      end

      def unpack(buffer = nil)
        tags = []

        while(buffer.length > 0)
          tag, len = nil, nil

          if @big_endian
            tag, len = buffer.unpack("a4L")
          else
            tag, len = buffer.unpack("a4N")
          end

          data = buffer[8...8+len]

          buffer[0...8+len] = ''

          type = @@types[tag]['TYPE']

          if type == 12
            data = unpack(data)
          elsif type == 7
            n1, n2 = @big_endian ? data.unpack("L2") : data.unpack("N2")
            data = n1 << 32
            data += n2
          else
            data = data.unpack(@type_to_unpack[type])
          end

          if data.class == Array && data.length == 1 && data[0].class != Array || type == 11
            tmp = [ @@types[tag]['NAME'], data[0]]
          else
            tmp = [ @@types[tag]['NAME'], data]
          end

          tags << tmp
        end
        tags
      end

      def seek(struct, to_find)
        while( to_find != nil && to_find.length > 0 )
          top, to_find = to_find.split('/', 2)

          found = nil
          struct.each do |element|
            if element[0] == top
              found = element[1]
            end
          end
          return unless found
          struct = found
        end
        return struct
      end

      @@types = 
          {
            'abal' => {
                        'ID' => 'abal',
                        'NAME' => 'daap.browsealbumlisting',
                        'TYPE' => 12
                      },
            'abar' => {
                        'ID' => 'abar',
                        'NAME' => 'daap.browseartistlisting',
                        'TYPE' => 12
                      },
            'abcp' => {
                        'ID' => 'abcp',
                        'NAME' => 'daap.browsecomposerlisting',
                        'TYPE' => 12
                      },
            'abgn' => {
                        'ID' => 'abgn',
                        'NAME' => 'daap.browsegenrelisting',
                        'TYPE' => 12
                      },
            'abpl' => {
                        'ID' => 'abpl',
                        'NAME' => 'daap.baseplaylist',
                        'TYPE' => 1
                      },
            'abro' => {
                        'ID' => 'abro',
                        'NAME' => 'daap.databasebrowse',
                        'TYPE' => 12
                      },
            'adbs' => {
                        'ID' => 'adbs',
                        'NAME' => 'daap.databasesongs',
                        'TYPE' => 12
                      },
            'aeNV' => {
                        'ID' => 'aeNV',
                        'NAME' => 'com.apple.itunes.norm-volume',
                        'TYPE' => 5
                      },
            'aeSP' => {
                        'ID' => 'aeSP',
                        'NAME' => 'com.apple.itunes.smart-playlist',
                        'TYPE' => 1
                      },
            'aply' => {
                        'ID' => 'aply',
                        'NAME' => 'daap.databaseplaylists',
                        'TYPE' => 12
                      },
            'apro' => {
                        'ID' => 'apro',
                        'NAME' => 'daap.protocolversion',
                        'TYPE' => 11
                      },
            'apso' => {
                        'ID' => 'apso',
                        'NAME' => 'daap.playlistsongs',
                        'TYPE' => 12
                      },
            'arif' => {
                        'ID' => 'arif',
                        'NAME' => 'daap.resolveinfo',
                        'TYPE' => 12
                      },
            'arsv' => {
                        'ID' => 'arsv',
                        'NAME' => 'daap.resolve',
                        'TYPE' => 12
                      },
            'asal' => {
                        'ID' => 'asal',
                        'NAME' => 'daap.songalbum',
                        'TYPE' => 9
                      },
            'asar' => {
                        'ID' => 'asar',
                        'NAME' => 'daap.songartist',
                        'TYPE' => 9
                      },
            'asbr' => {
                        'ID' => 'asbr',
                        'NAME' => 'daap.songbitrate',
                        'TYPE' => 3
                      },
            'asbt' => {
                        'ID' => 'asbt',
                        'NAME' => 'daap.songbeatsperminute',
                        'TYPE' => 3
                      },
            'ascm' => {
                        'ID' => 'ascm',
                        'NAME' => 'daap.songcomment',
                        'TYPE' => 9
                      },
            'asco' => {
                        'ID' => 'asco',
                        'NAME' => 'daap.songcompilation',
                        'TYPE' => 1
                      },
            'ascp' => {
                        'ID' => 'ascp',
                        'NAME' => 'daap.songcomposer',
                        'TYPE' => 9
                      },
            'asda' => {
                        'ID' => 'asda',
                        'NAME' => 'daap.songdateadded',
                        'TYPE' => 10
                      },
            'asdb' => {
                        'ID' => 'asdb',
                        'NAME' => 'daap.songdisabled',
                        'TYPE' => 1
                      },
            'asdc' => {
                        'ID' => 'asdc',
                        'NAME' => 'daap.songdisccount',
                        'TYPE' => 3
                      },
            'asdk' => {
                        'ID' => 'asdk',
                        'NAME' => 'daap.songdatakind',
                        'TYPE' => 1
                      },
            'asdm' => {
                        'ID' => 'asdm',
                        'NAME' => 'daap.songdatemodified',
                        'TYPE' => 10
                      },
            'asdn' => {
                        'ID' => 'asdn',
                        'NAME' => 'daap.songdiscnumber',
                        'TYPE' => 3
                      },
            'asdt' => {
                        'ID' => 'asdt',
                        'NAME' => 'daap.songdescription',
                        'TYPE' => 9
                      },
            'aseq' => {
                        'ID' => 'aseq',
                        'NAME' => 'daap.songeqpreset',
                        'TYPE' => 9
                      },
            'asfm' => {
                        'ID' => 'asfm',
                        'NAME' => 'daap.songformat',
                        'TYPE' => 9
                      },
            'asgn' => {
                        'ID' => 'asgn',
                        'NAME' => 'daap.songgenre',
                        'TYPE' => 9
                      },
            'asrv' => {
                        'ID' => 'asrv',
                        'NAME' => 'daap.songrelativevolume',
                        'TYPE' => 1
                      },
            'assp' => {
                        'ID' => 'assp',
                        'NAME' => 'daap.songstoptime',
                        'TYPE' => 5
                      },
            'assr' => {
                        'ID' => 'assr',
                        'NAME' => 'daap.songsamplerate',
                        'TYPE' => 5
                      },
            'asst' => {
                        'ID' => 'asst',
                        'NAME' => 'daap.songstarttime',
                        'TYPE' => 5
                      },
            'assz' => {
                        'ID' => 'assz',
                        'NAME' => 'daap.songsize',
                        'TYPE' => 5
                      },
            'astc' => {
                        'ID' => 'astc',
                        'NAME' => 'daap.songtrackcount',
                        'TYPE' => 3
                      },
            'astm' => {
                        'ID' => 'astm',
                        'NAME' => 'daap.songtime',
                        'TYPE' => 5
                      },
            'astn' => {
                        'ID' => 'astn',
                        'NAME' => 'daap.songtracknumber',
                        'TYPE' => 3
                      },
            'asul' => {
                        'ID' => 'asul',
                        'NAME' => 'daap.songdataurl',
                        'TYPE' => 9
                      },
            'asur' => {
                        'ID' => 'asur',
                        'NAME' => 'daap.songuserrating',
                        'TYPE' => 1
                      },
            'asyr' => {
                        'ID' => 'asyr',
                        'NAME' => 'daap.songyear',
                        'TYPE' => 3
                      },
            'avdb' => {
                        'ID' => 'avdb',
                        'NAME' => 'daap.serverdatabases',
                        'TYPE' => 12
                      },
            'mbcl' => {
                        'ID' => 'mbcl',
                        'NAME' => 'dmap.bag',
                        'TYPE' => 12
                      },
            'mccr' => {
                        'ID' => 'mccr',
                        'NAME' => 'dmap.contentcodesresponse',
                        'TYPE' => 12
                      },
            'mcna' => {
                        'ID' => 'mcna',
                        'NAME' => 'dmap.contentcodesname',
                        'TYPE' => 9
                      },
            'mcnm' => {
                        'ID' => 'mcnm',
                        'NAME' => 'dmap.contentcodesnumber',
                        'TYPE' => 9
                      },
            'mcon' => {
                        'ID' => 'mcon',
                        'NAME' => 'dmap.container',
                        'TYPE' => 12
                      },
            'mctc' => {
                        'ID' => 'mctc',
                        'NAME' => 'dmap.containercount',
                        'TYPE' => 5
                      },
            'mcti' => {
                        'ID' => 'mcti',
                        'NAME' => 'dmap.containeritemid',
                        'TYPE' => 5
                      },
            'mcty' => {
                        'ID' => 'mcty',
                        'NAME' => 'dmap.contentcodestype',
                        'TYPE' => 3
                      },
            'mdcl' => {
                        'ID' => 'mdcl',
                        'NAME' => 'dmap.dictionary',
                        'TYPE' => 12
                      },
            'miid' => {
                        'ID' => 'miid',
                        'NAME' => 'dmap.itemid',
                        'TYPE' => 5
                      },
            'mikd' => {
                        'ID' => 'mikd',
                        'NAME' => 'dmap.itemkind',
                        'TYPE' => 1
                      },
            'mimc' => {
                        'ID' => 'mimc',
                        'NAME' => 'dmap.itemcount',
                        'TYPE' => 5
                      },
            'minm' => {
                        'ID' => 'minm',
                        'NAME' => 'dmap.itemname',
                        'TYPE' => 9
                      },
            'mlcl' => {
                        'ID' => 'mlcl',
                        'NAME' => 'dmap.listing',
                        'TYPE' => 12
                      },
            'mlid' => {
                        'ID' => 'mlid',
                        'NAME' => 'dmap.sessionid',
                        'TYPE' => 5
                      },
            'mlit' => {
                        'ID' => 'mlit',
                        'NAME' => 'dmap.listingitem',
                        'TYPE' => 12
                      },
            'mlog' => {
                        'ID' => 'mlog',
                        'NAME' => 'dmap.loginresponse',
                        'TYPE' => 12
                      },
            'mpco' => {
                        'ID' => 'mpco',
                        'NAME' => 'dmap.parentcontainerid',
                        'TYPE' => 5
                      },
            'mper' => {
                        'ID' => 'mper',
                        'NAME' => 'dmap.persistentid',
                        'TYPE' => 7
                      },
            'mpro' => {
                        'ID' => 'mpro',
                        'NAME' => 'dmap.protocolversion',
                        'TYPE' => 11
                      },
            'mrco' => {
                        'ID' => 'mrco',
                        'NAME' => 'dmap.returnedcount',
                        'TYPE' => 5
                      },
            'msal' => {
                        'ID' => 'msal',
                        'NAME' => 'dmap.supportsautologout',
                        'TYPE' => 1
                      },
            'msau' => {
                        'ID' => 'msau',
                        'NAME' => 'dmap.authenticationmethod',
                        'TYPE' => 1
                      },
            'msbr' => {
                        'ID' => 'msbr',
                        'NAME' => 'dmap.supportsbrowse',
                        'TYPE' => 1
                      },
            'msdc' => {
                        'ID' => 'msdc',
                        'NAME' => 'dmap.databasescount',
                        'TYPE' => 5
                      },
            'msex' => {
                        'ID' => 'msex',
                        'NAME' => 'dmap.supportsextensions',
                        'TYPE' => 1
                      },
            'msix' => {
                        'ID' => 'msix',
                        'NAME' => 'dmap.supportsindex',
                        'TYPE' => 1
                      },
            'mslr' => {
                        'ID' => 'mslr',
                        'NAME' => 'dmap.loginrequired',
                        'TYPE' => 1
                      },
            'mspi' => {
                        'ID' => 'mspi',
                        'NAME' => 'dmap.supportspersistentids',
                        'TYPE' => 1
                      },
            'msqy' => {
                        'ID' => 'msqy',
                        'NAME' => 'dmap.supportsquery',
                        'TYPE' => 1
                      },
            'msrs' => {
                        'ID' => 'msrs',
                        'NAME' => 'dmap.supportsresolve',
                        'TYPE' => 1
                      },
            'msrv' => {
                        'ID' => 'msrv',
                        'NAME' => 'dmap.serverinforesponse',
                        'TYPE' => 12
                      },
            'mstm' => {
                        'ID' => 'mstm',
                        'NAME' => 'dmap.timeoutinterval',
                        'TYPE' => 5
                      },
            'msts' => {
                        'ID' => 'msts',
                        'NAME' => 'dmap.statusstring',
                        'TYPE' => 9
                      },
            'mstt' => {
                        'ID' => 'mstt',
                        'NAME' => 'dmap.status',
                        'TYPE' => 5
                      },
            'msup' => {
                        'ID' => 'msup',
                        'NAME' => 'dmap.supportsupdate',
                        'TYPE' => 1
                      },
            'mtco' => {
                        'ID' => 'mtco',
                        'NAME' => 'dmap.specifiedtotalcount',
                        'TYPE' => 5
                      },
            'mudl' => {
                        'ID' => 'mudl',
                        'NAME' => 'dmap.deletedidlisting',
                        'TYPE' => 12
                      },
            'mupd' => {
                        'ID' => 'mupd',
                        'NAME' => 'dmap.updateresponse',
                        'TYPE' => 12
                      },
            'musr' => {
                        'ID' => 'musr',
                        'NAME' => 'dmap.serverrevision',
                        'TYPE' => 5
                      },
            'muty' => {
                        'ID' => 'muty',
                        'NAME' => 'dmap.updatetype',
                        'TYPE' => 1
                      },
            'pasp' => {
                        'ID' => 'pasp',
                        'NAME' => 'dpap.aspectratio',
                        'TYPE' => 9
                      },
            'pfdt' => {
                        'ID' => 'pfdt',
                        'NAME' => 'dpap.picturedata',
                        'TYPE' => 42
                      },
            'picd' => {
                        'ID' => 'picd',
                        'NAME' => 'dpap.creationdate',
                        'TYPE' => 5
                      },
            'pimf' => {
                        'ID' => 'pimf',
                        'NAME' => 'dpap.imagefilename',
                        'TYPE' => 9
                      },
            'ppro' => {
                        'ID' => 'ppro',
                        'NAME' => 'dpap.protocolversion',
                        'TYPE' => 11
                      }
          }
    end
  end
end
