# frozen_string_literal: true
require_relative 'constants'
# Create initial .mygit directories and subfolders structure
module Repository
  include Constants

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
