# frozen_string_literal: true

require 'digest'
require 'zlib'
require 'fileutils'

# Organize Git Structures
class GitRepo
  DIR_MYGIT = '.mygit'.freeze
  DIR_OBJECTS = "#{DIR_MYGIT}/objects".freeze
  DIR_REFS = "#{DIR_MYGIT}/refs".freeze
  FILE_HEAD = "#{DIR_MYGIT}/HEAD".freeze

  def self.create
    new.create
  end

  def self.hash_object(file, write: nil)
    new.hash_object(file, write)
  end

  def self.print(hash, mode)
    new.print(hash, mode)
  end

  def create
    if Dir.exist? DIR_MYGIT
      puts 'Mygit Already initialized'
      exit 1
    end

    Dir.mkdir DIR_MYGIT
    Dir.mkdir DIR_OBJECTS
    Dir.mkdir DIR_REFS
    File.write(FILE_HEAD, "ref: refs/heads/master\n")
  end

  def hash_object(file, write)
    store = build_blob(file)
    hashed_obj = Digest::SHA1.hexdigest(store)

    return hashed_obj unless write

    location = object_location(hashed_obj)
    compressed_object = Zlib::Deflate.deflate(store)

    write_file(location[:dir], location[:filename], compressed_object)

    hashed_obj
  end

  def print(hash, mode)
    decompressed_file = decompress_file(hash)
    return decompressed_file[:content] if mode == 'content'

    decompressed_file[:type].split.first
  end

  private

  def decompress_file(hash)
    location = object_location(hash)

    compressed_file = File.binread("#{location[:dir]}/#{location[:filename]}")

    decompressed_file = Zlib::Inflate.inflate(compressed_file)

    type, content = decompressed_file.split("\0", 2)
    
    {
      type:,
      content:
    }
  end

  def object_location(hash)
    hash_dir_name = hash.slice 0..1
    dir = "#{DIR_OBJECTS}/#{hash_dir_name}"
    filename = hash.slice 2..-1

    {
      dir:,
      filename:
    }
  end

  def write_file(dir, filename, compressed_file)
    FileUtils.mkdir_p(dir)

    File.open("#{dir}/#{filename}", 'wb') do |f|
      f.write(compressed_file)
    end
  end

  def build_blob(file)
    content = File.read(file)
    size_in_bytes = content.bytesize
    header = "blob #{size_in_bytes}\0"
    header + content
  end
end
