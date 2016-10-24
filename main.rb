#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift('lib')

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'adjustlibris'

if !File.exist?(ARGV[0])
  raise Errno::ENOENT, ARGV[0]
end

if !ARGV[1] || ARGV[1].empty?
  puts "Usage: $0 input_file.marc output_file.marc"
  exit
end

AdjustLibris.run(input_file: ARGV[0], output_file: ARGV[1])
