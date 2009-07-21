if RUBY_VERSION > "1.8.2"
class Net::InternetMessageIO #:nodoc:
  alias :old_rbuf_fill :rbuf_fill
  def rbuf_fill
    begin
      @rbuf << @io.read_nonblock(65536)
    rescue Errno::EWOULDBLOCK
      if IO.select([@io], nil, nil, @read_timeout)
        @rbuf << @io.read_nonblock(65536)
      else
        raise Timeout::TimeoutError
      end
    end
  end
end
else
class Net::InternetMessageIO #:nodoc:
  alias :old_rbuf_fill :rbuf_fill
  def rbuf_fill
    timeout(@read_timeout) {
      @rbuf << @socket.sysread(8192)
    }
  end
end
end
