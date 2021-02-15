require 'spec_helper'

RSpec.describe Shrine::Storage::WebDAV do
  let(:host) { 'http://localhost/webdav' }
  let(:dir) { 'dir' }
  let(:file_name) { 'file_name.pdf' }
  subject { described_class.new(host: host) }

  describe '#upload' do
    let(:file) { double.tap { |file| allow(file).to receive(:read).and_return('content') } }

    context 'when id includes subdirectories' do
      it 'creates subdirectory and uploads file in it' do
        mkcol_stab = stub_request(:mkcol, "#{host}/#{dir}").to_return(status: 200)
        put_stab = stub_request(:put, "#{host}/#{dir}/#{file_name}").to_return(status: 200)
        subject.upload(file, "#{dir}/#{file_name}")
        expect(mkcol_stab).to have_been_requested
        expect(put_stab).to have_been_requested
      end
    end

    context 'when id does not include subdirectories' do
      it 'uploads file in the root directory' do
        put_stab = stub_request(:put, "#{host}/#{file_name}").to_return(status: 200)
        subject.upload(file, "#{file_name}")
        expect(put_stab).to have_been_requested
      end
    end

    context 'when prefix presented' do
      let(:prefix) { 'prefix/cache' }

      it 'creates initial directory, creates subdirectory and uploads file in it' do
        stab1      = stub_request(:mkcol, "#{host}/prefix").to_return(status: 200)
        stab2      = stub_request(:mkcol, "#{host}/prefix/cache").to_return(status: 200)
        mkcol_stab = stub_request(:mkcol, "#{host}/prefix/cache/#{dir}").to_return(status: 200)
        put_stab   = stub_request(:put,   "#{host}/prefix/cache/#{dir}/#{file_name}").to_return(status: 200)

        described_class.new(host: host, prefix: prefix).upload(file, "#{dir}/#{file_name}")

        expect(stab1).to have_been_requested
        expect(stab2).to have_been_requested
        expect(mkcol_stab).to have_been_requested
        expect(put_stab).to have_been_requested
      end
    end

    context 'when create_full_put_path option is set to true' do
      let(:prefix) { 'prefix/cache' }
      let(:upload_options) { {create_full_put_path: true} }
      let!(:put_stab) { stub_request(:put, "#{host}/prefix/cache/#{dir}/#{file_name}").to_return(status: 200) }

      it 'uploads file in its full path' do
        storage = described_class.new(host: host, prefix: prefix, upload_options: upload_options)
        storage.upload(file, "#{dir}/#{file_name}")
        expect(put_stab).to have_been_requested
      end

      it 'uploads file in its full path' do
        storage = described_class.new(host: host, prefix: prefix)
        storage.upload(file, "#{dir}/#{file_name}", upload_options)
        expect(put_stab).to have_been_requested
      end
    end

    context 'when timeout option is presented' do
      let(:prefix) { 'prefix/cache' }
      let(:http_options) { {timeout: 3} }

      it 'uploads file' do
        stub_request(:mkcol, "#{host}/prefix").to_return(status: 200)
        stub_request(:mkcol, "#{host}/prefix/cache").to_return(status: 200)
        stub_request(:mkcol, "#{host}/prefix/cache/#{dir}").to_return(status: 200)
        put_stub = stub_request(:put,   "#{host}/prefix/cache/#{dir}/#{file_name}").to_return(status: 200)

        storage = described_class.new(host: host, prefix: prefix, http_options: http_options)
        storage.upload(file, "#{dir}/#{file_name}")
        expect(put_stub).to have_been_requested
      end

      context 'when timeout is presented as a hash' do
        let(:prefix) { 'prefix/cache' }
        let(:http_options) { {timeout: {connect: 5, write: 2, read: 10}} }

        it 'uploads file' do
          stub_request(:mkcol, "#{host}/prefix").to_return(status: 200)
          stub_request(:mkcol, "#{host}/prefix/cache").to_return(status: 200)
          stub_request(:mkcol, "#{host}/prefix/cache/#{dir}").to_return(status: 200)
          put_stub = stub_request(:put, "#{host}/prefix/cache/#{dir}/#{file_name}").to_return(status: 200)

          storage = described_class.new(host: host, prefix: prefix, http_options: http_options)
          storage.upload(file, "#{dir}/#{file_name}")
          expect(put_stub).to have_been_requested
        end
      end
    end

    context 'when basic_auth option is presented' do
      let(:prefix) { 'prefix/cache' }
      let(:http_options) { {basic_auth: {user: 'user', pass: 'pass'}} }

      it 'uploads file' do
        stub_request(:mkcol, "#{host}/prefix").to_return(status: 200)
        stub_request(:mkcol, "#{host}/prefix/cache").to_return(status: 200)
        stub_request(:mkcol, "#{host}/prefix/cache/#{dir}").to_return(status: 200)
        put_stub = stub_request(:put, "#{host}/prefix/cache/#{dir}/#{file_name}").to_return(status: 200)

        storage = described_class.new(host: host, prefix: prefix, http_options: http_options)
        storage.upload(file, "#{dir}/#{file_name}")
        expect(put_stub).to have_been_requested
      end
    end
  end

  describe '#url' do
    let(:id) { "#{dir}/#{file_name}" }

    it 'returns file id which is also a path to the file' do
      expect(subject.url(id)).to eq("#{host}/#{id}")
    end

    it 'returns url with specified :host' do
      custom_host = 'https://cdn.example.com'
      expect(subject.url(id, host: custom_host)).to eq("#{custom_host}/#{id}")
    end

    it 'returns url with specified :prefix' do
      custom_prefix = 'uploads'
      expect(subject.url(id, prefix: custom_prefix)).to eq("#{host}/#{custom_prefix}/#{id}")
    end

    it 'returns url with specified :host and :prefix' do
      custom_host = 'https://cdn.example.com'
      custom_prefix = 'uploads'
      expect(subject.url(id, host: custom_host, prefix: custom_prefix)).to eq("#{custom_host}/#{custom_prefix}/#{id}")
    end
  end

  describe '#open' do
    context 'when file exists' do
      it 'downloads the file and save it to temporary file' do
        stab = stub_request(:get, "#{host}/#{dir}/#{file_name}").to_return(status: 200, body: 'test_content')
        tempfile = subject.open("#{dir}/#{file_name}")
        expect(tempfile).to be_instance_of(Down::ChunkedIO)
        expect(tempfile.read).to eq('test_content')
        expect(stab).to have_been_requested
      end
    end

    context 'when http timeout set' do
      it 'raises exception' do
        expect do
          storage = described_class.new(host: host, http_options: { timeout: { connect: 5 } })
          stab = stub_request(:get, "#{host}/#{dir}/wrong_name").to_timeout
          storage.open("#{dir}/wrong_name")
          expect(stab).to have_been_requested
        end.to raise_error(Down::TimeoutError)
      end
    end

    context 'when file does not exist' do
      it 'raises exception' do
        expect {
          stab = stub_request(:get, "#{host}/#{dir}/wrong_name").to_return(status: 404)
          subject.open("#{dir}/wrong_name")
          expect(stab).to have_been_requested
        }.to raise_error(Down::NotFound)
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
