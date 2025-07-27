require 'digest'
require_relative 'constants'
require_relative 'hash_object'
require_relative 'commons'

class Staging
  include Constants
  include Commons
  
  ALL_FILES = '.'.freeze

  def self.add(files)
    new.add(files)
  end

  def self.status
    new.status
  end

  def recursive_search(dir, found)
    keep_entries = ['.gitignore', '.rspec']
    Dir.foreach(dir) do |entry|
      next if entry == '.' || entry == '..'
      next if entry.start_with?('.') && !keep_entries.include?(entry)
      path = File.join(dir, entry)
      stat = File.stat(path)
      mode = stat.directory? ? '40000' : '100644'
      
      if stat.file?
        sha = HashObject.call(path, write: true)
      elsif stat.directory?
        recursive_search(path, found)
      end
      
      found << "#{mode} #{entry}\0 #{sha}\n"
    end

    found
  end

  def add(files)
    # checking if files were in the index at first place!!
    
    if empty_commits?
      entries = []
      dir = Dir.pwd

      tracked_files = recursive_search(dir, entries)
      
      File.write(INDEX_FILE, tracked_files.join)
      
      msg = tracked_files.map {|f| f.split[1] }.map {|f| f.split("\0")}
      
      puts "Files added to staging:\n #{msg.flatten.join(', ')}"
    end
    
    byebug
    exit 1
    File.write(INDEX_FILE, 'oi') if !File.exist?(INDEX_FILE) 
    
    modified_files = []
    
    files.each do |file|
      indexed = File.read(INDEX_FILE).include?(file)
      if indexed
        current_sha = HashObject.call(file, write: false)
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

  def empty_commits?
    last_commit_ref_path = File.read(HEAD_FILE).strip.split.last # refs/heads/main
    
    File.exist?(last_commit_ref_path) == false
  end

  def read_head
    File.read(HEAD_FILE).strip.split.last # refs/heads/main
  end

  def status
    # compare index vs HEAD -> detect staged changes -> changes to be committed
    # compare working Dir vs index -> unstaged changes -> changes not staged to the commit
    # compare working Dir vs index -> new, untracked files -> untracked files

    if empty_commits?
      branch = read_head.gsub!("refs/heads/",'')
      puts "On branch #{branch}\n\n"
      puts "No commits yet\n\n"
      puts "Nothing to commit (create/copy files and use 'iamgit add' to track)"

      exit 1
    end

    indexed_files = File.readlines(INDEX_FILE) if index?



    index_list = {}
    

    indexed_files.each do |file_info|
      file_info.strip! #["100644", "hello.txt", "0142824230f3fafbcb268341063276ed745b142e"]
      mode     = file_info.split[0]
      filename = file_info.split[1]
      sha = file_info.split[2]

      index_list[filename] = {
        mode: mode,
        sha: sha
      }
    end

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

    decompressed_tree_file.split.each do |item|
      byebug
    end
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

  private

  def new_index_entry(file)
    mode = '100644'
    blob = build_blob(file)
    sha1 = Digest::SHA1.hexdigest(blob)
    "#{mode} #{file} #{sha1}\n"
  end
end