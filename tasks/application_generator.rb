module ActiveAdmin
  class ApplicationGenerator
    attr_reader :rails_env, :template, :parallel

    def initialize(opts = {})
      @rails_env = opts[:rails_env] || 'test'
      @template = opts[:template] || 'rails_template'
      @parallel = opts[:parallel]
    end

    def generate
      unless correctly_configured_app?
        puts "App is not correctly configured for running tests #{running_mode}. (Re)building #{app_dir} App. Please wait."
        system("rm -Rf #{app_dir}")
      end

      if app_exists?
        puts "test app #{app_dir} already exists and correctly configured; skipping test app generation"
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

        env = base_env
        env['INSTALL_PARALLEL'] = 'yes' if parallel

        Bundler.with_original_env { Kernel.system(env, command) }

        rails_app_rake "parallel:load_schema" if parallel
      end
    end

    private

    def base_env
      { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] }
    end

    def running_mode
      parallel ? "in parallel" : "sequentially"
    end

    def correctly_configured_app?
      app_exists? && !(parallel ^ parallel_tests_setup?)
    end

    def app_exists?
      File.exist? app_dir
    end

    def rails_app_rake(task)
      env = base_env

      Bundler.with_original_env do
        Dir.chdir(app_dir) { system(env, "bundle exec rake #{task}") }
      end
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

    def parallel_tests_setup?
      database_config = File.join app_dir, "config", "database.yml"
      File.exist?(database_config) && File.read(database_config).include?("TEST_ENV_NUMBER")
    end
  end
end
