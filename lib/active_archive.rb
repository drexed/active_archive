require 'rails'

%w[version settings table_definition methods scopes base].each do |file_name|
  require "active_archive/#{file_name}"
end

require 'generators/active_archive/install_generator'

module ActiveArchive
  class Railtie < ::Rails::Railtie

    initializer 'active_archive' do |app|
      ActiveArchive::Railtie.instance_eval do
        [app.config.i18n.available_locales].flatten.each do |locale|
          (I18n.load_path << path(locale)) if File.file?(path(locale))
        end
      end
    end

    def self.path(locale)
      File.expand_path("../../config/locales/#{locale}.yml", __FILE__)
    end

  end
end
