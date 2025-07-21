# frozen_string_literal: true

require 'digest'
require 'zlib'
require 'fileutils'
require 'byebug'

# Organize Git Structures
class Repository
  MYGIT_DIR = '.mygit'.freeze
  OBJECTS_DIR = "#{MYGIT_DIR}/objects".freeze
  REFS_DIR = "#{MYGIT_DIR}/refs".freeze
  HEAD_FILE = "#{MYGIT_DIR}/HEAD".freeze
  INDEX_FILE = "#{MYGIT_DIR}/index".freeze

  def self.create
    new.create
  end

  def self.hash_object(file, write: nil)
    new.hash_object(file, write)
  end

  def self.print(hash, mode)
    new.print(hash, mode)
  end

  def self.commit(tree, message)
    new.commit(tree, message)
  end

  def self.add(files)
    new.add(files)
  end

  def create
    if Dir.exist? MYGIT_DIR
      puts 'Mygit Already initialized'
      exit 1
    end

    Dir.mkdir MYGIT_DIR
    Dir.mkdir OBJECTS_DIR
    Dir.mkdir REFS_DIR
    File.write(HEAD_FILE, "ref: refs/heads/main\n")
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

  def commit(tree, message)
    timestamp = Time.now.to_i

    head_ref = File.read(FILE_HEAD).strip.split.last
    ref_path = File.join(MYGIT_DIR, head_ref)

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

    dir = "#{OBJECTS_DIR}/#{sha1[0..1]}"
    filename = sha1[2..]

    FileUtils.mkdir_p(dir)
    File.open("#{dir}/#{filename}", 'wb') { |f| f.write(compressed)}
    FileUtils.mkdir_p(File.dirname(ref_path))
    File.write(ref_path, sha1)
    
    sha1
  end

  def add(files)
    # checking if files were in the index at first place!!
    File.write(INDEX_FILE, '') if !File.exist?(INDEX_FILE) 
    
    modified_files = []

    files.each do |file|
      indexed = File.read(INDEX_FILE).include?(file)
      if indexed
        current_sha = hash_object(file, write: false)
        indexed_sha = ''
        
        lines = File.readlines(INDEX_FILE)

        lines.map! do |line|
          next if !line.include?(file)
          indexed_sha = line.strip.split.last
          line = new_index_entry(file) if current_sha != indexed_sha
        end
        File.write(INDEX_FILE, lines.join) if current_sha != indexed_sha
      else
        modified_files << file
      end
    end
    
    # writing files to index
    modified_files.each do |file|
      new_entry = new_index_entry(file)
      File.write(INDEX_FILE, new_entry, mode: 'a+') #append mode
    end
  end

  def new_index_entry(file)
    mode = '100644'
    blob = build_blob(file)
    sha1 = Digest::SHA1.hexdigest(blob)
    "#{mode} #{file} #{sha1}\n"
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
    dir = "#{OBJECTS_DIR}/#{hash_dir_name}"
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
