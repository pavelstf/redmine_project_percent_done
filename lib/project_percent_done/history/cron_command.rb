require 'shellwords'

module ProjectPercentDone
  module History
    class CronCommand
      RAKE_TASK = 'redmine:project_percent_done:snapshots'.freeze
      LOG_FILE = 'log/project_percent_done_snapshots.log'.freeze
      SCHEDULE_EXAMPLE = '5 0 * * *'.freeze

      attr_reader :rails_root, :rails_env, :virtual_env

      def initialize(rails_root: Rails.root.to_s, rails_env: Rails.env.to_s, virtual_env: nil)
        @rails_root = rails_root.to_s
        @rails_env = rails_env.to_s
        @virtual_env = virtual_env.nil? ? detected_virtual_env : virtual_env.to_s.presence
      end

      def rake_command
        "bundle exec rake #{RAKE_TASK} RAILS_ENV=#{Shellwords.escape(rails_env)}"
      end

      def full_command
        commands = []
        commands << "source #{Shellwords.escape(activation_path)}" if virtual_env.present?
        commands << "cd #{Shellwords.escape(rails_root)}"
        commands << "#{rake_command} >> #{Shellwords.escape(LOG_FILE)} 2>&1"

        "/bin/bash -lc #{single_quote(commands.join(' && '))}"
      end

      def virtual_env_detected?
        virtual_env.present?
      end

      private

      def detected_virtual_env
        gem_paths = ENV['GEM_PATH'].to_s.split(File::PATH_SEPARATOR)
        [ENV['VIRTUAL_ENV'], ENV['GEM_HOME'], *gem_paths].compact.uniq.find do |path|
          File.file?(File.join(path, 'bin', 'activate'))
        end
      end

      def activation_path
        File.join(virtual_env, 'bin', 'activate')
      end

      def single_quote(value)
        "'#{value.to_s.gsub("'", %q('"'"'))}'"
      end
    end
  end
end
