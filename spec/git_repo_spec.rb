require 'fileutils'
require 'tmpdir'
require_relative "../backend/lib/git_repo"

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
    expect(content.strip).to eq ("ref: refs/heads/master")
  end
end
