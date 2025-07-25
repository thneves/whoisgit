require 'zlib'
require_relative 'constants'
class Status
  include Constants

  def self.check
    new.check
  end

  def check
   index = File.read(INDEX_FILE) if index?
   index_sha1 = Zlib::Deflate.deflate(index) 

   index_hash = {
    mode: '100644',
    sha1: index_sha1
   }

   latest_commit_tree = File.read(HEAD_FILE)
   ref_path = latest_commit_tree.strip.split.last
   last_commit_sha1 = File.read("#{MYGIT_DIR}/#{ref_path}")

   dir = last_commit_sha1[0..1]
   filename = last_commit_sha1[2..]

   file_path = "#{OBJECTS_DIR}/#{dir}/#{filename}"

   file = File.read(file_path)

   file = sha_file_finder(last_commit_sha1)
   decompressed_file = Zlib::Inflate.inflate(file)

   tree_sha1 = decompressed_file.split[2]

   tree_file = sha_file_finder(tree_sha1)

   decompressed_tree_file = Zlib::Inflate.inflate(tree_file)
   
   byebug
   puts "inprogrss"
  end

  def sha_file_finder(sha)
    dir = sha[0..1]
    filename = sha[2..]
    path = "#{OBJECTS_DIR}/#{dir}/#{filename}"
    File.read(path)
  end

  def index?
    File.exist? INDEX_FILE
  end
end