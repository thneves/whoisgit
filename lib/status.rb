require 'zlib'
require_relative 'constants'
class Status
  include Constants

  def self.check
    new.check
  end

  def check
  # compare index vs HEAD -> detect staged changes -> changes to be committed
  # compare working Dir vs index -> unstaged changes -> changes not staged to the commit
  # compare working Dir vs index -> new, untracked files -> untracked files
  
   index = File.read(INDEX_FILE) if index?
   
   index_hash = {}

   index_sha = index.strip.split.last
   index_filename = index.strip.split[1]

   index_hash[index_filename] = { #hello.txt
    mode: '100644',
    sha1: index_sha
   }

   latest_commit_tree = File.read(HEAD_FILE)
   ref_path = latest_commit_tree.strip.split.last # refs/heads/main
   last_commit_sha1 = File.read("#{MYGIT_DIR}/#{ref_path}") # "98bc26ea437c926bfc14473b0661f26bf9e6f5a6"

   dir = last_commit_sha1[0..1] # 98
   filename = last_commit_sha1[2..] # bc26ea437c926bfc14473b0661f26bf9e6f5a6

   file_path = "#{OBJECTS_DIR}/#{dir}/#{filename}" # ".mygit/objects/98/bc26ea437c926bfc14473b0661f26bf9e6f5a6"

   file = File.read(file_path) # BINARY FILE "x\x9C\x95\x8DK\u000E\xC20 ....

   file = sha_file_finder(last_commit_sha1, binary: true) # BINARY FILE "x\x9C\x95\x8DK\u000E\xC20 ....
   
   decompressed_commit_file = Zlib::Inflate.inflate(file) # "commit 153\x00tree bc4a9474db732ffa3e5b6d47c8a5e924a02cc202\nauthor thales thales@iamgit.com 1753237221 +0000\ncommitter thales thales@iamgit.com 1753237221 +0000\noioioi"

   commit_tree_sha = decompressed_commit_file.split[3]  # bc4a9474db732ffa3e5b6d47c8a5e924a02cc202

   commit_tree_file = sha_file_finder(commit_tree_sha, binary: true) # BINARY FILE from commit 

   decompressed_tree_file = Zlib::Inflate.inflate(commit_tree_file) # "tree 312\x00100644 .rspec\x00\xC9\x9D.s\x96\xE1J\xC0r\xC6>\xC8A\x9D\x9B\x8F\xED\xE2\x8D\x8640000 ...

   byebug

   head_tree = {

   }
   
   puts "inprogrss"
  end

  def sha_file_finder(sha, binary: false)
    dir = sha[0..1]
    filename = sha[2..]
    path = "#{OBJECTS_DIR}/#{dir}/#{filename}"
    return File.binread(path) if binary
    File.read(path)
  end

  def index?
    File.exist? INDEX_FILE
  end
end