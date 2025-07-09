class GitRepo
  def self.create
    new.create
  end
  
  def create
    return "Already Exists" if repo_exist? # Follow git and implement reinitialize repo
    
    Dir.mkdir(".mygit")
    Dir.mkdir(".mygit/objects")
    Dir.mkdir(".mygit/refs")
    Dir.mkdir(".mygit/HEAD")

  end

  def repo_exist?
    Dir.exist? ".mygit"
  end
end