require 'spec_helper'

RSpec.describe Shrine::Storage::WebDAV do
  let(:host) { 'http://localhost/webdav' }

  describe '.new' do
    it 'initializes storage and creates initial directory tree there' do
      stab1 = stub_request(:mkcol, "#{host}/prefix").to_return(status: 200)
      stab2 = stub_request(:mkcol, "#{host}/prefix/cache").to_return(status: 200)
      described_class.new(host: host, prefix: 'prefix/cache')
      expect(stab1).to have_been_requested
      expect(stab2).to have_been_requested
    end
  end

  subject { described_class.new(host: host) }
  let(:dir) { 'dir' }
  let(:file_name) { 'file_name.pdf' }

  describe '#upload' do
    let(:file) { double.tap { |file| allow(file).to receive(:read).and_return('content') } }

    it 'creates subdirectory and uploads file in it' do
      mkcol_stab = stub_request(:mkcol, "#{host}/#{dir}").to_return(status: 200)
      put_stab = stub_request(:put, "#{host}/#{dir}/#{file_name}").to_return(status: 200)
      subject.upload(file, "#{dir}/#{file_name}")
      expect(mkcol_stab).to have_been_requested
      expect(put_stab).to have_been_requested
    end
  end

  describe '#url' do
    let(:id) { "#{dir}/#{file_name}" }

    it 'returns file id which is also a path to the file' do
      expect(subject.url(id)).to eq(id)
    end
  end

  describe '#open' do
    context 'when file exists' do
      it 'downloads the file and save it to temporary file' do
        stab = stub_request(:get, "#{host}/#{dir}/#{file_name}").to_return(status: 200, body: 'test_content')
        tempfile = subject.open("#{dir}/#{file_name}")
        expect(tempfile).to be_instance_of(Tempfile)
        expect(tempfile.read).to eq('test_content')
        expect(stab).to have_been_requested
      end
    end

    context 'when file does not exist' do
      it 'raises exception' do
        expect {
          stab = stub_request(:get, "#{host}/#{dir}/wrong_name").to_return(status: 404)
          subject.open("#{dir}/wrong_name")
          expect(stab).to have_been_requested
        }.to raise_error(StandardError)
      end
    end
  end

  describe '#exists?' do
    context 'when file exists' do
      it 'returns true' do
        stab = stub_request(:head, "#{host}/#{dir}/#{file_name}").to_return(status: 200)
        response = subject.exists?("#{dir}/#{file_name}")
        expect(response).to be(true)
        expect(stab).to have_been_requested
      end
    end

    context 'when file does not exist' do
      it 'returns false' do
        stab = stub_request(:head, "#{host}/#{dir}/wrong_name").to_return(status: 404)
        response = subject.exists?("#{dir}/wrong_name")
        expect(response).to be(false)
        expect(stab).to have_been_requested
      end
    end

    describe '#delete' do
      context 'when file exists' do
        it 'removes the file' do
          stab = stub_request(:delete, "#{host}/#{dir}/#{file_name}").to_return(status: 200)
          response = subject.delete("#{dir}/#{file_name}")
          expect(response.status).to eq(200)
          expect(stab).to have_been_requested
        end
      end

      context 'when file does not exist' do
        it 'does not remove the file' do
          stab = stub_request(:delete, "#{host}/#{dir}/wrong_name").to_return(status: 404)
          response = subject.delete("#{dir}/wrong_name")
          expect(response.status).to eq(404)
          expect(stab).to have_been_requested
        end
      end
    end
  end
end
