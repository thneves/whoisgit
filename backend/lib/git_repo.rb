require 'digest'
class GitRepo
  def self.create
    new.create
  end

  def self.hash_object(file)
    new.hash_object(file)
  end
  
  def create
    return "Already Exists" if Dir.exist? ".mygit" # Follow git and implement reinitialize repo
    
    Dir.mkdir(".mygit")
    Dir.mkdir(".mygit/objects")
    Dir.mkdir(".mygit/refs")
    File.write(".mygit/HEAD", "ref: refs/heads/master\n")
  end

  def hash_object(file)
    content = File.read(file)
    size_in_bytes = content.bytesize
    header = "blob #{size_in_bytes}\0"
    store = header + content
    Digest::SHA1.hexdigest(store)
  end
end