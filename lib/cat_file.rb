require_relative 'constants'

class CatFile
  include Constants

  def self.call(hash, mode)
    new.call(hash, mode)
  end

  def call(hash, mode)
    decompressed_file = decompress_file(hash)
    return decompressed_file[:content] if mode == 'content'

    decompressed_file[:type].split.first
  end

  private

  def decompress_file(hash)
    location = object_location(hash)

    compressed_file = File.binread("#{location[:dir]}/#{location[:filename]}")

    decompressed_file = Zlib::Inflate.inflate(compressed_file)

    type, content = decompressed_file.split("\0", 2)
    
    {
      type:,
      content:
    }
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
end