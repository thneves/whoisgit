#!/usr/bin/env ruby

require_relative '../backend/lib/git_repo'

command = ARGV.shift

case command
when "init"
  GitRepo.create
else
  puts "Unknown command: #{command}"
end