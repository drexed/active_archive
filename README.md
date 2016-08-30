# ActiveArchive

[![Gem Version](https://badge.fury.io/rb/active_archive.svg)](http://badge.fury.io/rb/active_archive)
[![Build Status](https://travis-ci.org/drexed/active_archive.svg?branch=master)](https://travis-ci.org/drexed/active_archive)
[![Coverage Status](https://coveralls.io/repos/github/drexed/active_archive/badge.svg?branch=master)](https://coveralls.io/github/drexed/active_archive?branch=master)

ActiveArchive is a library for preventing database records from being destroyed.

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
* [Methods](#methods)
* [Scopes](#scopes)

## Configurations

**Options:**
 * all_records_archivable
 * dependent_record_window

`rails generate active_archive:install` will generate the following `active_archive.rb` file:

```ruby
# Path: ../config/initalizers/active_archive.rb

ActiveArchive::Settings.configure do |config|
  config.all_records_archivable = false
  config.dependent_record_window = 3.seconds
end
```

## Methods

**Options:**
 * archive
 * destroy
 * destroy_all
 * delete
 * delete_all
 * unarchive
 * unarchive_all

```ruby
User.first.archive         #=> archives User record and dependents
User.first.destroy         #=> archives User record and dependents
User.first.delete          #=> deletes User record and dependents
User.first.unarchive       #=> unarchives User record and dependents

User.first.to_archival     #=> returns archival state string

User.first.archive(:force) #=> destroys User record and dependents
User.first.destroy(:force) #=> destroys User record and dependents

User.archive_all           #=> archives all User records and dependents
User.destroy_all           #=> archives all User records and dependents
User.delete_all            #=> deletes all User records and dependents
User.unarchive_all         #=> unarchives all User record and dependents
```

## Scopes

**Options:**
 * default
 * archived
 * unarchived

```ruby
User.all            #=> returns all records
User.archived.all   #=> returns only archived record
User.unarchived.all #=> returns only unarchived record
```

## Contributing

Your contribution is welcome.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
