#!/usr/bin/env ruby

host = ARGV[0]
port = ARGV[1]

require 'socket'

include Socket::Constants
socket = Socket.new(AF_INET, SOCK_STREAM, 0)
sockaddr = Socket.sockaddr_in(port, host)

tries = 15
sleep_seconds = 0.3

begin
  socket.connect_nonblock(sockaddr)
rescue IO::WaitWritable
  IO.select(nil, [socket])
  begin
    socket.connect_nonblock(sockaddr)
  rescue IO::EINPROGRESSWaitWritable, Errno::ECONNREFUSED
    if tries > 0
      tries -= 1
      sleep sleep_seconds
      retry
    else
      exit 1
    end
  rescue Errno::EISCONN
  end
end

exit 0
