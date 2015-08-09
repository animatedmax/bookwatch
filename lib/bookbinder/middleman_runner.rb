require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'yaml'

module Bookbinder
  class MiddlemanRunner
    def initialize(streams, fs, sheller)
      @streams = streams
      @fs = fs
      @sheller = sheller
    end

    def run(output_locations,
            config,
            local_repo_dir,
            verbosity,
            subnav_templates_by_directory)
      streams[:out].puts "\nRunning middleman...\n\n"
      Dir.chdir(output_locations.master_dir) do
        config = {
          archive_menu: config.archive_menu,
          production_host: config.public_host,
          subnav_templates: subnav_templates_by_directory,
          template_variables: config.template_variables,
          local_repo_dir: local_repo_dir,
          workspace: output_locations.workspace_dir,
        }
        fs.write(to: "bookbinder_config.yml", text: YAML.dump(config))
        sheller.run_command({'MM_ROOT' => output_locations.master_dir.to_s},
                            "middleman build #{verbosity_levels[verbosity]}",
                            streams)
      end
    end

    private

    attr_reader :streams, :fs, :sheller

    def verbosity_levels
      {
        true => "--verbose",
        false => "--no-verbose"
      }
    end
  end
end
