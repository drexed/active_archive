require "rails/generators"

module ActiveArchive
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    def copy_initializer_file
      copy_file("install.rb", "config/initializers/active_archive.rb")
    end

  end
end
