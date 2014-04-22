require 'tmpdir'

module BitbucketMigration
	class WorkDir
    attr_reader :path

    # Used to create temporary directory to store source git repository
    def initialize
      dir = Dir.mktmpdir

      if Dir.exists?(dir)
        @path = dir
      else
        raise RuntimeError.new("Unable to create temporary directory")
      end
    end

    # Cleanup method to force removal of temporary directory
    # with all its contents 
    def clean!
      FileUtils.remove_entry_secure @path
      @path = nil
    end

    alias_method :clean, :clean!
	end
end