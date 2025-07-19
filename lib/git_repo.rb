# frozen_string_literal: true

require 'digest'
require 'zlib'
require 'fileutils'
require 'byebug'

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

  def self.write_tree
    new.write_tree
  end

  def self.commit(tree, message)
    new.commit(tree, message)
  end

  def self.add(files)
    new.add(files)
  end

  def create
    if Dir.exist? DIR_MYGIT
      puts 'Mygit Already initialized'
      exit 1
    end

    Dir.mkdir DIR_MYGIT
    Dir.mkdir DIR_OBJECTS
    Dir.mkdir DIR_REFS
    File.write(FILE_HEAD, "ref: refs/heads/main\n")
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

  def write_tree(dir = Dir.pwd) # takes dir from the project
    entries = []
    keep_entries = ['.gitignore', '.rspec']

    Dir.foreach(dir) do |entry|
      next if entry == '.' || entry == '..'
      next if entry.start_with?('.') && !keep_entries.include?(entry)
      path = File.join(dir, entry)
      stat = File.stat(path)
      mode = stat.directory? ? '40000' : '100644'

      if stat.directory?
        hash = write_tree(path)
      elsif stat.file?
        hash = hash_object(path, write: true) # header + content -> blob + size \0 content -> Hashed SHA1 4f8c8d91ed08a61dd25d700513da917a68a1f8cc
      else
        next
      end
      binary_hash = [hash].pack("H*") # "\xC9\x9D.s\x96\xE1J\xC0r\xC6>\xC8A\x9D\x9B\x8F\xED\xE2\x8D\x86" fucking binary
      entries << "#{mode} #{entry}\0" + binary_hash # "100644 .filename \0 binary"
    end

    tree_content = entries.join
    store = "tree #{tree_content.bytesize}\0" + tree_content
    sha = Digest::SHA1.hexdigest(store)

    dir_name = "#{DIR_OBJECTS}/#{sha[0..1]}"
    file_name = sha[2..]
    FileUtils.mkdir_p(dir_name)
    File.open("#{dir_name}/#{file_name}", 'wb') do |f|
      f.write(Zlib::Deflate.deflate(store))
    end

    sha
  end

  def commit(tree, message)
    timestamp = Time.now.to_i

    head_ref = File.read(FILE_HEAD).strip.split.last
    ref_path = File.join(DIR_MYGIT, head_ref)

    parent = File.exist?(ref_path) ? File.read(ref_path).strip : nil

    commit_body = "tree #{tree}\n"
    commit_body << "parent #{parent}\n" if parent
    commit_body << "author thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << "committer thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << message
    
    size = commit_body.bytesize
    commit_header = "commit #{size}\0"

    store = commit_header + commit_body
    
    puts store

    sha1 = Digest::SHA1.hexdigest(store)
    compressed = Zlib::Deflate.deflate(store)

    dir = "#{DIR_OBJECTS}/#{sha1[0..1]}"
    filename = sha1[2..]

    FileUtils.mkdir_p(dir)
    File.open("#{dir}/#{filename}", 'wb') { |f| f.write(compressed)}
    FileUtils.mkdir_p(File.dirname(ref_path))
    File.write(ref_path, sha1)
    
    sha1
  end

  def add(files)
    puts files
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
