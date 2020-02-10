#!/usr/bin/env crun

FS_TAGGING_SENTINEL_FILENAME = ".this_is_an_fs_tagging_folder"
DEFAULT_FS_TAGGING_FOLDER = ".fs_tagging_manual"

def usage(error = nil)
  if error
    STDERR.puts "ERROR: #{error}"
    puts
  end

  STDERR.puts "Usage: #{File.basename(PROGRAM_NAME)} <tag> <file> [<file> ..]"
end

def check_fs_tagging_dir?(dir : String)
  if File.exists? File.join(dir, FS_TAGGING_SENTINEL_FILENAME)
    dir
  else
    nil
  end
end

def find_fs_tagging_dir
  if check_fs_tagging_dir? "."
    return "."
  end

  dir = ENV["FS_TAGGING_DIR"]? || DEFAULT_FS_TAGGING_FOLDER
  return dir if check_fs_tagging_dir? dir
  nil
end

unless fs_tagging_dir = find_fs_tagging_dir
  usage "FS tagging folder (default: #{DEFAULT_FS_TAGGING_FOLDER}) not found"
  exit 1
end

if ARGV.size < 2
  usage "Bad nb args (given #{ARGV.size}, expected 2 or more)"
  exit 1
end

# --------------------------------------------

tag = ARGV.shift
files = ARGV

if files.empty?
  usage "No files specified"
  exit 1
end

files.each do |f_path|
  unless File.exists? f_path
    STDERR.puts "File not found (#{f_path})"
    exit 1
  end
end

tag_dir = File.join(fs_tagging_dir, "tags", tag)

unless Dir.exists? tag_dir
  STDERR.puts <<-HELP
    Tag '#{tag}' does not exist yet, you need to create its folder first:

    mkdir -vp '#{tag_dir}'

    HELP
  exit 1
end

files.each do |f_path|
  f_basename = File.basename f_path

  tagged_f_path = File.join(tag_dir, f_basename)

  if File.exists?(tagged_f_path)
    puts "File '#{f_basename}' is already tagged with '#{tag}'"
  else
    # hardlink the file to `tag_dir`
    File.link(f_path, tagged_f_path)

    puts "File '#{f_basename}' tagged with '#{tag}'"
  end
end
