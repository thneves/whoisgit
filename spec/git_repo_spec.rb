# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../backend/lib/git_repo'

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

    before do
      File.write(filename, content)
      GitRepo.create
    end

    it 'returns the original content of the blob' do
      hash = GitRepo.hash_object(filename, write: true)
      result = GitRepo.print(hash)

      expect(result).to eq(content)
    end
  end
end
