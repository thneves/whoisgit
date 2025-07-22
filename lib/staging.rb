require_relative 'constants'

class Staging
  include Constants  
  
  def self.add(files)
    new.add(files)
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

  private

  def new_index_entry(file)
    mode = '100644'
    blob = build_blob(file)
    sha1 = Digest::SHA1.hexdigest(blob)
    "#{mode} #{file} #{sha1}\n"
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

  def build_blob(file)
    content = File.read(file)
    size_in_bytes = content.bytesize
    header = "blob #{size_in_bytes}\0"
    header + content
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
end