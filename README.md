# ActiveArchive

[![Gem Version](https://badge.fury.io/rb/active_archive.svg)](http://badge.fury.io/rb/active_archive)
[![Build Status](https://travis-ci.org/drexed/active_archive.svg?branch=master)](https://travis-ci.org/drexed/active_archive)

**NOTE** ActiveArchive has been deprecated in favor of [Lite::Archive](https://github.com/drexed/lite-archive). Its a drop-in replacement, so please make the switch as soon as possible.

ActiveArchive is a library for preventing database records from being destroyed.

**NOTE: version >= '6.0.0' has a breaking change with the migration timestamps, initializer options, and model/record callbacks.**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_archive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_archive

## Table of Contents

* [Configurations](#configurations)
* [Usage](#usage)
* [Methods](#methods)
* [Scopes](#scopes)
* [Callbacks](#callbacks)

## Configurations

`rails g active_archive:install` will generate the following file:
`../config/initalizers/active_archive.rb`

```ruby
ActiveArchive.configure do |config|
  config.all_records_archivable = false
end
```

## Usage
To work properly, models which could be archived must have column `archived_at` with type `datetime`. If the model table has not this column, record will be destroy instead of archived.


For adding this column, you can use this migration, as example:

```ruby
class AddArchivedAtColumns < ActiveRecord::Migration
  def change
    # Adds archived_at automatically
    t.timestamp

    # Does NOT add archived_at automatically
    t.timestamp archive: false

    # Manual column
    add_column :your_model, :archived_at, :datetime
  end
end
```

## Methods

**Options:**
 * `archive`
 * `archive_all`
 * `unarchive`
 * `unarchive_all`

```ruby
User.first.archive          #=> archives User record and dependents
User.first.unarchive        #=> unarchives User record and dependents

User.first.to_archival      #=> returns archival state string

User.archive_all            #=> archives all User records and dependents
User.unarchive_all          #=> unarchives all User record and dependents
```

## Scopes

**Options:**
 * `archived`
 * `unarchived`

```ruby
User.archived.all           #=> returns only archived record
User.unarchived.all         #=> returns only unarchived record
```

## Callbacks

**Options:**
 * `before_archive`
 * `before_unarchived`
 * `after_archive`
 * `after_unarchive`

## Contributing

Your contribution is welcome.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
