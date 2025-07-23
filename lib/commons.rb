require  'zlib'
require 'fileutils'

module Commons
  def write_binary_file(dir, filename, compressed_file)
    FileUtils.mkdir_p(dir)
    File.open("#{dir}/#{filename}", 'wb') do |f|
      f.write(compressed_file)
    end
  end

  def build_blob(file)
    content = File.read(file)
    size_in_bytes = content.bytesize
    header = "blob #{size_in_bytes}\0"
    header + content
  end
end