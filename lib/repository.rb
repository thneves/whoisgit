# frozen_string_literal: true

# Create initial .mygit directories and subfolders structure
module Repository
  MYGIT_DIR = '.mygit'.freeze
  OBJECTS_DIR = "#{MYGIT_DIR}/objects".freeze
  REFS_DIR = "#{MYGIT_DIR}/refs".freeze
  HEAD_FILE = "#{MYGIT_DIR}/HEAD".freeze

  def self.init
    if Dir.exist? MYGIT_DIR
      puts 'Mygit Already initialized'
      exit 1
    end

    Dir.mkdir MYGIT_DIR
    Dir.mkdir OBJECTS_DIR
    Dir.mkdir REFS_DIR
    File.write(HEAD_FILE, "ref: refs/heads/main\n")
  end
end
