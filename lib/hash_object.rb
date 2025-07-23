
require 'digest'
require 'zlib'
require 'fileutils'
require_relative 'constants'
require_relative 'commons'

class HashObject
  include Constants
  include Commons

  def self.call(file, write)
    new.call(file, write)
  end

  def call(file, write)
    store = build_blob(file)
    hashed_obj = Digest::SHA1.hexdigest(store)

    return hashed_obj unless write

    location = object_location(hashed_obj)
    compressed_object = Zlib::Deflate.deflate(store)

    write_binary_file(location[:dir], location[:filename], compressed_object)

    hashed_obj
  end

  private

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