#!/usr/bin/env ruby

require "./things_org.rb"

extra_file_name = ARGV[0]
exit 1 unless extra_file_name

merger = ItemJsonMerger.new
Dir.glob("items.*.json").each do |json_file_path|
  merger.add(json_file_path)
end

puts ThingsOrg.new(merger.to_json).make_extra(extra_file_name)
