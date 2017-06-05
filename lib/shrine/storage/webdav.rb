require 'shrine'
require 'http'
require 'down/http'

class Shrine
  module Storage
    class WebDAV
      def initialize(host:, prefix: nil, upload_options: {})
        @host = host
        @prefix = prefix
        @prefixed_host = path(@host, @prefix)
        @upload_options = upload_options
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        options = current_options(upload_options)
        mkpath_to_file(id) unless options[:create_full_put_path]
        put(id, io)
      end

      def url(id, **options)
        id
      end

      def open(id)
        Down::Http.open(path(@prefixed_host, id))
      end

      def exists?(id)
        response = HTTP.head(path(@prefixed_host, id))
        (200..299).cover?(response.code.to_i)
      end

      def delete(id)
        HTTP.delete(path(@prefixed_host, id))
      end

      private

      def current_options(upload_options)
        options = {}
        options.update(@upload_options)
        options.update(upload_options)
      end

      def put(id, io)
        uri = path(@prefixed_host, id)
        response = HTTP.put(uri, body: io.read)
        return if (200..299).cover?(response.code.to_i)
        raise Error, "uploading of #{uri} failed, the server response was #{response}"
      end

      def path(host, uri)
        (uri.nil? || uri.empty?) ? host : [host, uri].compact.join('/')
      end

      def mkpath_to_file(path_to_file)
        @prefix_created ||= create_prefix
        last_slash = path_to_file.rindex('/')
        if last_slash
          path = path_to_file[0..last_slash]
          mkpath(@prefixed_host, path)
        end
      end

      def create_prefix
        mkpath(@host, @prefix) unless @prefix.nil? || @prefix.empty?
      end

      def mkpath(host, path)
        dirs = []
        path.split('/').each do |dir|
          dirs << "#{dirs[-1]}/#{dir}"
        end
        dirs.each do |dir|
          response = HTTP.request(:mkcol, "#{host}#{dir}")
          unless (200..301).cover?(response.code.to_i)
            raise Error, "creation of directory #{host}#{dir} failed, the server response was #{response}"
          end
        end
      end
    end
  end
end
