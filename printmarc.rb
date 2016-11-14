#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)


puts "######################################################"
puts "# Printing #{ARGV[0]}"
puts "######################################################"
reader = MARC::Reader.new(ARGV[0])
reader.each do |record|
  puts "------------------------------------------------------------------------------------------"
  puts record
end
