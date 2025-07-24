require 'digest'
require_relative 'constants'
require_relative 'hash_object'
require_relative 'commons'

class Staging
  include Constants
  include Commons
  
  def self.add(files)
    new.add(files)
  end

  def self.add(files)
    # checking if files were in the index at first place!!
    File.write(INDEX_FILE, '') if !File.exist?(INDEX_FILE) 
    
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

  private

  def new_index_entry(file)
    mode = '100644'
    blob = build_blob(file)
    sha1 = Digest::SHA1.hexdigest(blob)
    "#{mode} #{file} #{sha1}\n"
  end
end