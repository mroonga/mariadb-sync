#!/usr/bin/env ruby

require "English"
require "pathname"
require "fileutils"

cmakelists_txt = Pathname(ARGV[0])

resolved_content = ""
cmakelists_txt.open do |file|
  file.each_line do |line|
    resolved_line = line.gsub(/(\$\{MRN_TEST_SUITE_DIR\})(\/\S+)/) do
      prefix = $1
      components = $2.split("/")
      mode = components.first
      targets = components[1..-3]
      type = components[-2]
      targets << components.last
      resolved_path = [mode, type, targets.join("_")].join("/")
      prefix + resolved_path
    end
    resolved_content << resolved_line
  end
end
cmakelists_txt.open("w") do |file|
  file.print(resolved_content)
end
