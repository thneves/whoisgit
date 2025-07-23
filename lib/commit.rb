require 'digest'
require 'fileutils'
require 'zlib'

require_relative 'constants'

class Commit
  include Constants

  def self.call(tree, message)
    new.call(tree, message)
  end

  def call(tree, message)
    timestamp = Time.now.to_i

    head_ref = File.read(HEAD_FILE).strip.split.last
    ref_path = File.join(MYGIT_DIR, head_ref)

    parent = File.exist?(ref_path) ? File.read(ref_path).strip : nil

    commit_body = "tree #{tree}\n"
    commit_body << "parent #{parent}\n" if parent
    commit_body << "author thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << "committer thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << message
    
    size = commit_body.bytesize
    commit_header = "commit #{size}\0"

    store = commit_header + commit_body
    
    puts store

    sha1 = Digest::SHA1.hexdigest(store)
    compressed = Zlib::Deflate.deflate(store)

    dir = "#{OBJECTS_DIR}/#{sha1[0..1]}"
    filename = sha1[2..]

    FileUtils.mkdir_p(dir)
    File.open("#{dir}/#{filename}", 'wb') { |f| f.write(compressed)}
    FileUtils.mkdir_p(File.dirname(ref_path))
    File.write(ref_path, sha1)
    
    sha1
  end
end