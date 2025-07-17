# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'zlib'
require 'digest'
require_relative '..//lib/git_repo'

RSpec.describe GitRepo do
  around(:each) do |example|
    Dir.mktmpdir do  |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end

  subject { GitRepo.create }

  describe '#create' do
    it 'creates .mygit directory' do
      subject
      expect(Dir.exist?('.mygit')).to be true
    end
  end

  it 'creates objects, refs and HEAD directories inside .mygit' do
    subject
    expect(Dir.exist?('.mygit/objects')).to be true
    expect(Dir.exist?('.mygit/refs')).to be true
  end

  it 'creates the HEAD file with correct content' do
    subject

    head_path = '.mygit/HEAD'
    expect(File.exist?(head_path)).to be true

    content = File.read(head_path)
    expect(content.strip).to eq('ref: refs/heads/master')
  end

  describe '#hash_object' do
    let(:filename) { 'test.txt' }
    let(:content) { 'hello world' }

    before do
      File.write(filename, content)
    end

    it 'returns correct SHA-1 hash of blob content' do
      blob = "blob #{content.bytesize}\0#{content}"
      expected_hash = Digest::SHA1.hexdigest(blob)

      result = GitRepo.hash_object(filename, write: false)
      expect(result).to eq(expected_hash)
    end

    it 'produces same hash as real Git' do
      expected_hash = `git hash-object #{filename}`.strip
      result = GitRepo.hash_object(filename, write: false)

      expect(result).to eq(expected_hash)
    end

    it 'writes the compressed blob to the correct path when write is true' do
      result = GitRepo.hash_object(filename, write: true)

      dir = result[0..1]
      file = result[2..]
      path = ".mygit/objects/#{dir}/#{file}"

      expect(File.exist?(path)).to be true
    end

    it 'writes the correct zlib-compressed blob content' do
      result = GitRepo.hash_object(filename, write: true)

      dir = result[0..1]
      file = result[2..]
      path = ".mygit/objects/#{dir}/#{file}"

      compressed_data = File.binread(path)
      decompressed = Zlib::Inflate.inflate(compressed_data)

      expected_blob = "blob #{content.bytesize}\0#{content}"
      expect(decompressed).to eq(expected_blob)
    end
  end

  describe '#print' do
    let(:filename) { 'hello.txt' }
    let(:content) { 'hello from test' }
    let(:hash) { GitRepo.hash_object(filename, write: true) }
    let(:content_mode) { 'content' }
    let(:type_mode) { 'type' }

    before do
      File.write(filename, content)
      GitRepo.create
    end

    it 'returns the original content of the blob' do
      result = GitRepo.print(hash, content_mode)

      expect(result).to eq(content)
    end
  end

  describe '#write_tree' do
    let(:repo) { GitRepo.new }

    before do
      File.write('file1.txt', 'Hello')
      File.write('.gitignore', '*.log')
      FileUtils.mkdir_p('src')
      File.write('src/app.rb', 'puts "hi"')
    end

    it 'writes a tree object with correct SHA and content' do
      tree_sha = repo.write_tree

      # Load tree object from .mygit/objects
      dir = ".mygit/objects/#{tree_sha[0..1]}"
      file = "#{dir}/#{tree_sha[2..]}"
      compressed = File.binread(file)
      decompressed = Zlib::Inflate.inflate(compressed)

      expect(decompressed).to start_with("tree ")

      _, body = decompressed.split("\0", 2)

      expect(body).to include("100644 file1.txt")
      expect(body).to include("100644 .gitignore")
      expect(body).to include("40000 src")

      # Ensure it contains valid binary SHA hashes (20 bytes after each \0)
      entries = body.scan(/(100644|40000) [^\0]+\0(.{20})/m)
      entries.each do |(_, binary_hash)|
        expect(binary_hash.bytesize).to eq(20)
      end
    end

    it 'recursively includes subdirectories and their files' do
      tree_sha = repo.write_tree

      dir = ".mygit/objects/#{tree_sha[0..1]}"
      file = "#{dir}/#{tree_sha[2..]}"
      compressed = File.binread(file)
      decompressed = Zlib::Inflate.inflate(compressed)

      _, body = decompressed.split("\0", 2)

      # Confirm that 'src/app.rb' content was written to .mygit/objects
      expect(body).to include("40000 src")

      # Extract the SHA of 'src' tree
      src_entry = body[/40000 src\0(.{20})/m, 1]
      src_sha = src_entry.unpack1("H*")

      src_dir = ".mygit/objects/#{src_sha[0..1]}"
      src_file = "#{src_dir}/#{src_sha[2..]}"
      src_compressed = File.binread(src_file)
      src_decompressed = Zlib::Inflate.inflate(src_compressed)

      _, src_body = src_decompressed.split("\0", 2)

      expect(src_body).to include("100644 app.rb")
    end
  end
  describe '#commit' do
    let(:tree_sha) { 'a1b2c3d4e5f678901234567890abcdefabcdef12' }
    let(:message) { 'initial commit' }
    let(:parent_sha) { 'f1e2d3c4b5a678901234567890abcdefabcdef00' }
    let(:timestamp) { 1_752_717_000 }

    before do
      allow(Time).to receive(:now).and_return(Time.at(timestamp))
      FileUtils.mkdir_p(GitRepo::DIR_OBJECTS)
    end

    after do
      FileUtils.rm_rf(GitRepo::DIR_MYGIT)
    end

    it 'creates a valid commit object with parent' do
      sha = subject.commit(tree_sha, message, parent_sha)

      expect(sha).to match(/\A\h{40}\z/)

      dir = "#{GitRepo::DIR_OBJECTS}/#{sha[0..1]}"
      file = "#{dir}/#{sha[2..]}"
      expect(File.exist?(file)).to be true

      compressed = File.binread(file)
      decompressed = Zlib::Inflate.inflate(compressed)

      expected_body = <<~BODY
        tree #{tree_sha}
        parent #{parent_sha}author thales thales@iamgit.com #{timestamp} +0000
        committer thales thales@iamgit.com #{timestamp} +0000
        #{message}
      BODY

      expected_header = "commit #{expected_body.bytesize}\0"

      expect(decompressed).to eq(expected_header + expected_body)
    end

    it 'creates a valid commit object without parent' do
      sha = subject.commit(tree_sha, message, nil)

      dir = "#{GitRepo::DIR_OBJECTS}/#{sha[0..1]}"
      file = "#{dir}/#{sha[2..]}"
      decompressed = Zlib::Inflate.inflate(File.binread(file))

      expect(decompressed).to include("tree #{tree_sha}")
      expect(decompressed).not_to include("parent")
      expect(decompressed).to include("author thales thales@iamgit.com #{timestamp}")
      expect(decompressed).to include(message)
    end
  end
end
