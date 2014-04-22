module BitbucketMigration
  class GitRepository
    attr_reader :url, :name, :language

    def url=(url)
      if (url == nil or url.size == 0)
        raise ArgumentError.new("Repository URL cannot be empty")
      end
      @url = url
    end

    def name=(name)
      if (name == nil or name.size == 0)
        raise ArgumentError.new("Repository Name cannot be empty")
      end
      @name = name
    end

    def language=(language)
      if (language == nil or language.size == 0)
        @language = 'other'
      else
        @language = language
      end
    end

    # Holds values for specific git source repository
    def initialize(url, name, language)
      self.url      =url
      self.name     =name
      self.language =language
    end
  end
end