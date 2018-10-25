module ActiveAdmin
  class ApplicationGenerator
    attr_reader :rails_env, :template

    def initialize(opts = {})
      @rails_env = opts[:rails_env] || 'test'
      @template = opts[:template] || 'rails_template'
    end

    def generate
      if app_exists?
        puts "test app #{app_dir} already exists; skipping test app generation"
      else
        system "mkdir -p #{base_dir}"
        args = %W(
          -m spec/support/#{template}.rb
          --skip-bootsnap
          --skip-bundle
          --skip-gemfile
          --skip-listen
          --skip-turbolinks
          --skip-test-unit
          --skip-coffee
        )

        command = ['bundle', 'exec', 'rails', 'new', app_dir, *args].join(' ')

        Bundler.with_original_env { Kernel.system(env, command) }
      end
    end

    private

    def env
      { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] }
    end

    def app_exists?
      File.exist? app_dir
    end

    def base_dir
      @base_dir ||= rails_env == 'test' ? 'spec/rails' : '.test-rails-apps'
    end

    def app_dir
      @app_dir ||= begin
                     require 'rails/version'
                     "#{base_dir}/rails-#{Rails::VERSION::STRING}"
                   end
    end
  end
end
