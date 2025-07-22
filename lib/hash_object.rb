
require_relative 'constants'

class HashObject
  include Constants

  def self.call(file, write)
    new.call(file, write)
  end

  def call(file, write)
    store = build_blob(file)
    hashed_obj = Digest::SHA1.hexdigest(store)

    return hashed_obj unless write

    location = object_location(hashed_obj)
    compressed_object = Zlib::Deflate.deflate(store)

    write_file(location[:dir], location[:filename], compressed_object)

    hashed_obj
  end

  private

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