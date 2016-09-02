require 'rails'

%w(version railtie settings table_definition methods scopes base).each do |file_name|
  require "active_archive/#{file_name}"
end

require 'generators/active_archive/install_generator'
