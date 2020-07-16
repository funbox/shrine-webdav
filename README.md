# Shrine::Storage::WebDAV

[![Build Status](https://travis-ci.org/funbox/shrine-webdav.svg?branch=master)](https://travis-ci.org/funbox/shrine-webdav)

Provides a simple WebDAV storage for [Shrine](https://shrinerb.com/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shrine-webdav'
```

## Usage

Suppose you have Report model which should be able to store data in a remote WebDAV storage.

```ruby
class Report < ApplicationRecord
end
# == Schema Information
#
# Table name: reports
#
#  id                :uuid             not null, primary key
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
```

Before you start add attributes pointing to remote files to your model you should describe Uploader class:

```ruby
# app/models/reports/report_uploader.rb
class ReportUploader < Shrine
  plugin :activerecord
  plugin :logging, logger: Rails.logger

  def generate_location(_io, context)
    uuid = context[:record].id
    "#{uuid}.#{context[:name]}"
  end
end
```

You don't have to override method `generate_location`, but if you didn't you would have random file names.

Now you can add the attributes:

```ruby
class Report < ApplicationRecord
  include ReportUploader::Attachment.new(:pdf)
  include ReportUploader::Attachment.new(:xls)
end
```

Note corresponding migrations:

```ruby
class AddFileAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :reports, :xls_data, :text
    add_column :reports, :pdf_data, :text
  end
end
```

Create file `shrine.rb` in `config/initializers/` to configure WebDAV storage:

```ruby
# config/initializers/shrine.rb
require 'shrine'
require "shrine/storage/webdav"

Shrine.storages = {
  cache: Shrine::Storage::WebDAV.new(host: 'http://webdav-server.com', prefix: 'your_project/cache'),
  store: Shrine::Storage::WebDAV.new(host: 'http://webdav-server.com', prefix: 'your_project/store')
}
```

Now you can use your virtual attributes `pdf` and `xls` like this:

```ruby
report = Report.new(name: 'Senseless report')

# here you are going to have file sample.pdf uploaded
# to "http://webdav-server.com/your_project/cache/#{report.id}.pdf"
report.pdf = File.open('sample.pdf')

# file sample.xls is being uploading
# to "http://webdav-server.com/your_project/cache/#{report.id}.xls"
report.xls = File.open('sample.xls')

# after committing in database both files sample.pdf and sample.xls have
# been uploaded to "http://webdav-server.com/your_project/store/..."
report.save
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `shrine-webdav.gemspec`, and then run `bundle exec rake release`, 
which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/funbox/shrine-webdav. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[![Sponsored by FunBox](https://funbox.ru/badges/sponsored_by_funbox_centered.svg)](https://funbox.ru)
