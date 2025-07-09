#!/usr/bin/env ruby

command = ARGV.shift

case command
when "init"
  puts "INIT CALLED"
else
  puts "Unknown command: #{command}"
end