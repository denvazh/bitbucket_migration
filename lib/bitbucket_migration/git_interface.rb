require 'git'

module BitbucketMigration
  class GitInterface
    attr_reader :git, :src_repo, :target_repo, :remotes

    def src_repo=(src_repo)
      if (src_repo == nil)
        raise ArgumentError.new("Source repository value cannot be nil")
      end
      @src_repo = src_repo
    end

    def target_repo=(target_repo)
      if (target_repo == nil)
        raise ArgumentError.new("Cannot set target repository to nil")
      end
      @target_repo = target_repo
    end

    def initialize(src_repo, target_repo)
      self.src_repo     =src_repo
      self.target_repo  =target_repo
      @remotes ||= {:default => 'origin', :bitbucket => 'bitbucket'}.freeze
    end

    # Clones source repository to the temporary working directory
    def init_src_repo(workdir)
      if (workdir == nil or workdir.size == 0)
        raise ArgumentError.new("Unable to continue without working directory")
      else
        @git = Git.clone(@src_repo.url, @src_repo.name, :path => workdir)
      end
    end

    # Add remote reference to target repository ( in bitbucket )
    def init_target_repo
      @git.add_remote(@remotes[:bitbucket], @target_repo.ssh_href)
    end

    # Fetches all related remote branches and tags for source repository
    def fetch_src_repo_all
      @git.fetch
      @git.branches.remote.each do |rb|
        @git.checkout(rb.name) if !rb.name.match('^HEAD')
      end
    end

    # Push all related branches and tags to target repository
    def push_target_repo_all
      @git.branches.local.each do |lb|
        @git.push(@remotes[:bitbucket], lb.name, {:tags => true})
      end
    end
  end
end