#!/usr/bin/env ruby

require "./things_org.rb"

merger = ItemJsonMerger.new
Dir.glob("items.*.json").each do |json_file_path|
  merger.add(json_file_path)
end

puts ThingsOrg.new(merger.to_json).inbox_org
