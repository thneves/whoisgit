require  'zlib'
require 'fileutils'

module Commons
  def write_binary_file(dir, filename, compressed_file)
    FileUtils.mkdir_p(dir)
    File.open("#{dir}/#{filename}", 'wb') do |f|
      f.write(compressed_file)
    end
  end
end