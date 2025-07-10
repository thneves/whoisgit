# frozen_string_literal: true

require 'digest'
require 'zlib'
require 'fileutils'

# Organize Git Structures
class GitRepo
  def self.create
    new.create
  end

  def self.hash_object(file, write: nil)
    new.hash_object(file, write)
  end

  def create
    if Dir.exist? '.mygit'
      puts 'Mygit Already initialized'
      exit 1
    end

    Dir.mkdir('.mygit')
    Dir.mkdir('.mygit/objects')
    Dir.mkdir('.mygit/refs')
    File.write('.mygit/HEAD', "ref: refs/heads/master\n")
  end

  def hash_object(file, write)
    store = build_blob(file)
    hashed_obj = Digest::SHA1.hexdigest(store)

    return hashed_obj unless write

    hash_dir_name = hashed_obj.slice(0..1)
    hash_dir = ".mygit/objects/#{hash_dir_name}"
    filename = hashed_obj.slice(2..-1)
    compressed_object = Zlib::Deflate.deflate(store)

    write_file(hash_dir, filename, compressed_object)

    hashed_obj
  end

  private

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
