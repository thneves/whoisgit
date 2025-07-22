require_relative 'constants'

class Tree
  include Constants

  def self.write
    new.write
  end

  def write(dir = Dir.pwd) # takes dir from the project
    entries = []
    keep_entries = ['.gitignore', '.rspec']

    Dir.foreach(dir) do |entry|
      next if entry == '.' || entry == '..'
      next if entry.start_with?('.') && !keep_entries.include?(entry)
      path = File.join(dir, entry)
      stat = File.stat(path)
      mode = stat.directory? ? '40000' : '100644'

      if stat.directory?
        hash = write(path)
      elsif stat.file?
        hash = hash_object(path, write: true) # header + content -> blob + size \0 content -> Hashed SHA1 4f8c8d91ed08a61dd25d700513da917a68a1f8cc
      else
        next
      end
      binary_hash = [hash].pack("H*") # "\xC9\x9D.s\x96\xE1J\xC0r\xC6>\xC8A\x9D\x9B\x8F\xED\xE2\x8D\x86" fucking binary
      entries << "#{mode} #{entry}\0" + binary_hash # "100644 .filename \0 binary"
    end

    tree_content = entries.join
    store = "tree #{tree_content.bytesize}\0" + tree_content
    sha = Digest::SHA1.hexdigest(store)

    dir_name = "#{OBJECTS_DIR}/#{sha[0..1]}"
    file_name = sha[2..]
    FileUtils.mkdir_p(dir_name)
    File.open("#{dir_name}/#{file_name}", 'wb') do |f|
      f.write(Zlib::Deflate.deflate(store))
    end

    sha
  end

  private

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