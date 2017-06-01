require 'shrine'
require 'http'
require 'down/http'

class Shrine
  module Storage
    class WebDAV
      def initialize(host:, prefix: nil)
        @host = host
        mkpath(prefix) unless prefix.nil? || prefix.empty?
        @host = path(host, prefix)
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        mkpath_to_file(id)
        response = HTTP.put(path(@host, id), body: io.read)
        return if (200..299).cover?(response.code.to_i)
        raise Error, "uploading of #{path(@host, id)} failed, the server response was #{response}"
      end

      def url(id, **options)
        id
      end

      def open(id)
        Down::Http.open(path(@host, id))
      rescue Down::NotFound => exception
        raise Error, exception.message
      end

      def exists?(id)
        response = HTTP.head(path(@host, id))
        (200..299).cover?(response.code.to_i)
      end

      def delete(id)
        HTTP.delete(path(@host, id))
      end

      private

      def path(host, uri)
        [host, uri].compact.join('/')
      end

      def mkpath_to_file(path_to_file)
        last_slash = path_to_file.rindex('/')
        path = path_to_file[0..last_slash]
        mkpath(path)
      end

      def mkpath(path)
        dirs = []
        path.split('/').each do |dir|
          dirs << "#{dirs[-1]}/#{dir}"
        end
        dirs.each do |dir|
          response = HTTP.request(:mkcol, "#{@host}#{dir}")
          unless (200..301).cover?(response.code.to_i)
            raise Error, "creation of directory #{@host}#{dir} failed, the server response was #{response}"
          end
        end
      end
    end
  end
end
