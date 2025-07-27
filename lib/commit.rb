require 'digest'
require 'fileutils'
require 'zlib'

require_relative 'constants'
require_relative 'commons'

class Commit
  include Constants
  include Commons

  def self.call(tree, message)
    new.call(tree, message)
  end

  def call(tree, message)
    head_ref = File.read(HEAD_FILE).strip.split.last
    ref_path = File.join(MYGIT_DIR, head_ref)

    parent = File.exist?(ref_path) ? File.read(ref_path).strip : nil

    body = commit_body(tree, message, parent)
    size = body.bytesize
    header = "commit #{size} \0"

    store = header + body
    
    puts store

    sha1 = Digest::SHA1.hexdigest(store)
    compressed = Zlib::Deflate.deflate(store)

    dir = "#{OBJECTS_DIR}/#{sha1[0..1]}"
    filename = sha1[2..]

    write_binary_file(dir, filename, compressed)
    write_sha_file(ref_path, sha1)

    sha1
  end

  private

  def write_sha_file(ref_path,sha)
    FileUtils.mkdir_p(File.dirname(ref_path))
    File.write(ref_path, sha)
  end

  def commit_body(tree, message, parent)
    timestamp = Time.now.to_i

    commit_body = "tree #{tree}\n"
    commit_body << "parent #{parent}\n" if parent
    commit_body << "author thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << "committer thales thales@iamgit.com #{timestamp} +0000\n"
    commit_body << message
  end
end