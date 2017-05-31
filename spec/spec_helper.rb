require 'bundler/setup'
require 'webmock/rspec'
require 'shrine/webdav'

# TODO: remove once https://github.com/bblimke/webmock/pull/704 is merged
class HTTP::Response::Streamer
  def close
  end
end
