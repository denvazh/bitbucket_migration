require "bitbucket_migration/version"
require "bitbucket_migration/csv_import"
require "bitbucket_migration/configuration"
require "bitbucket_migration/git_repository"
require "bitbucket_migration/git_interface"
require "bitbucket_migration/git_workdir"
require "bitbucket_migration/api"
require 'optparse'

module BitbucketMigration

  # Main method implementing command line interface
  def self.run!(argv)
    options = {}
    opt_parser =OptionParser.new do |opts|
      opts.banner = "Usage: bitbucket_migration [options]"

      options[:config] = nil
      opts.on("-c", "--config FILE", String, "Configuration file with bitbucket credentials") do |conf|
        options[:config] = conf
      end

      options[:list] = nil
      opts.on("-l", "--list FILE", String, "List file in CSV format with repository migration information") do |list|
        options[:list] = list
      end

      opts.on("-h", "--help", "Show help") do |h|
        options[:help] = h
        puts opt_parser
        exit
      end

      opts.on("-v", "--version", "Show version") do |vers|
        options[:version] = vers
        puts BitbucketMigration::VERSION
        exit
      end
    end

    begin
      opt_parser.parse!(argv)

      required = [:config, :list]
      missing = required.select { |param| options[param].nil? }
      if not missing.empty?
        puts "Missing options: #{required.join(', ')}"
        puts opt_parser
        exit
      end

      begin
        config    =BitbucketMigration::Configuration.new(options[:config])
        list      =BitbucketMigration::CSVImport.new(options[:list])
        bitbucket =BitbucketMigration::Api.new(config.username, config.password, config.team)

        list.repositories.each do |src_repo|
          # Print current migration
          puts "Migrating repository #{src_repo.name}"
          workdir       =BitbucketMigration::WorkDir.new
          target_repo   =bitbucket.create_repository(src_repo.name, src_repo.language)
          if (bitbucket.repository_exists?(src_repo.name))
            gitinterface  =BitbucketMigration::GitInterface.new(src_repo, target_repo)
            gitinterface.init_src_repo(workdir.path)
            gitinterface.init_target_repo
            gitinterface.fetch_src_repo_all
            gitinterface.push_target_repo_all
          end
          workdir.clean!
        end
      rescue
        puts $!.to_s
        exit
      end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts opt_parser
      exit
    end
  end
end