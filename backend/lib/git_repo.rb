class GitRepo
  def self.create
    new.create
  end
  
  def create
    return "Already Exists" if repo_exist? # Follow git and implement reinitialize repo
    
    Dir.mkdir(".mygit")
    Dir.mkdir(".mygit/objects")
    Dir.mkdir(".mygit/refs")
    File.write(".mygit/HEAD", "ref: refs/heads/master\n")
  end

  def repo_exist?
    Dir.exist? ".mygit"
  end
end