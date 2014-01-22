#!/usr/bin/env ruby

require "English"
require "pathname"
require "fileutils"

base_dir = Pathname(ARGV[0])

top_t_dir = base_dir + "t"
top_r_dir = base_dir + "r"

relative_top_t_dir = top_t_dir.relative_path_from(base_dir)
relative_top_r_dir = top_r_dir.relative_path_from(base_dir)

def flatten_path(path)
  t_or_r = nil
  components = []
  path.descend do |component|
    base_name = component.basename.to_s
    if base_name == "t" or base_name == "r"
      t_or_r = base_name
      break
    end
    components << base_name
  end
  components << path.basename.to_s
  Pathname(t_or_r) + components.join("_")
end

def resolve_include_path(path, relative_path)
  content = path.open do |file|
    file.read
  end
  n_parents = relative_path.dirname.dirname.to_s.split("/").size
  resolved_content = ""
  content.each_line do |line|
    if line.valid_encoding?
      line = line.gsub(/^(--source )(\..*\/include\/mroonga\/.*)/) do
        prefix = $1
        mroonga_include_path = $2
        needless_path = "../" * n_parents
        mroonga_include_path = mroonga_include_path.gsub(/\A#{needless_path}/,
                                                         "")
        prefix + mroonga_include_path
      end
    end
    resolved_content << line
  end
  path.open("w") do |file|
    file.print(resolved_content)
  end
end

base_dir.find do |path|
  relative_path = path.relative_path_from(base_dir)
  case relative_path.extname
  when ".test"
    next if relative_path.dirname == relative_top_t_dir
    resolve_include_path(path, relative_path)
  when ".result"
    next if relative_path.dirname == relative_top_r_dir
  else
    next
  end
  FileUtils.mv(path.to_s,
               (base_dir + flatten_path(relative_path)).to_s)
end

base_dir.children.each do |child|
  next if top_t_dir == child
  next if top_r_dir == child
  FileUtils.rm_rf(child.to_s)
end
