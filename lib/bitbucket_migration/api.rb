require 'uri'
require 'rest-client'
require 'json'

module BitbucketMigration
  class Api
    attr :username, :password, :team, :endpoint

    def initialize(username, password, team)
      @username ||= username
      @password ||= password
      @team     ||= team
      @endpoint ||= Endpoint.new(@username, @password, @team)
    end

    # Get repository list #### TO-do rewrite to return array of Repository objects
    def get_repositories
      return JSON.parse(RestClient.get(@endpoint.repositories))
    end

    # Get information for specific repository
    def get_repository(name)
      raise ArgumentError.new("Unable to query with nil value for name") if name == nil
      response = RestClient.get(@endpoint.repository(name))
      if response.code == 200
        return Repository.new(JSON.parse(response))
      end
    end

    # Check if repository with given name exists on the bitbucket side
    def repository_exists?(name)
      raise ArgumentError.new("Unable to query with nil value for name") if name == nil
      begin
        repository = JSON.parse(RestClient.get(@endpoint.repository(name)))
        return repository['name'] == name ? true : false
      rescue RestClient::ResourceNotFound
        return false
      end
    end

    # Create new repository
    def create_repository(name, language=nil)
      raise ArgumentError.new("Unable to create repository if name is nil") if name == nil
      raise RuntimeError.new("Unable to create new repository over existing one") if self.repository_exists?(name)
      payload = { 'scm' => 'git', 'name' => name, 'is_private' => true }
      payload['language'] = language if language != nil

      # Sending POST request with payload
      response = RestClient.post(@endpoint.repository(name), payload.to_json, :content_type => :json, :accept => :json)
      if response.code == 200 || response.code == 201
        return self.get_repository(name)
      end     
    end

    # Delete existing repository
    def delete_repository(name)
      raise ArgumentError.new("Unable to delete repository if name is nil") if name == nil
      begin
        response = RestClient.delete(@endpoint.repository(name))
        case response.code
        when 200
        when 204
          return true
        else
          return false
        end
      rescue => e
        e.response
      end
    end

    # Handles URI generation used in requests to bitbucket
    class Endpoint
      attr_reader :userinfo, :host, :api, :version, :team, :keywords

      def initialize(username, password, team)
        self.set_userinfo(username, password)
        self.set_keywords
        @host     ||="bitbucket.org"
        @api      ||="api"
        @version  ||="2.0"
        @team     ||=team !=nil ? team : username
      end

      # Set userinfo with string of username:password 
      def set_userinfo(username, password)
        if (username == nil || password == nil)
          raise ArgumentError.new("Unable to set userinfo with empty values")
        end
        @userinfo ||=[username, password].join(":")
      end

      # Set endpoint keywords supported in bitbucket
      def set_keywords
        keywords = {}
        keywords[:repositories] = 'repositories'
        keywords[:users] = 'users'
        keywords[:teams] = 'teams'        
        @keywords ||= keywords
      end

      # Returns path for specified endpoint and tail(optional)
      def path(endpoint, tail=nil)
        if (endpoint == nil)
          raise ArgumentError.new("Unable to set path with nil endpoint")
        end
        _path = "/"
        tokens =[]
        [@api, @version, endpoint, @team, tail].each do |token|
          tokens.push(token) unless token.nil?          
        end
        _path << tokens.join('/')
      end

      # Generates uri string from default values and given path parameter
      def uri(path)
        raise ArgumentError.new("Unable to generate uri with nil path") if path == nil
        return URI::HTTPS.build(:userinfo => userinfo, :host => host, :path => path).to_s
      end

      # Returns URI for repositories
      def repositories
        return self.uri self.path(@keywords[:repositories])
      end

      # Returns URI for users
      def users
        return self.uri self.path(@keywords[:users])
      end

      # Returns URI for teams
      def teams
        return self.uri self.path(@keywords[:teams])
      end

      # Returns URI for specific repository
      def repository(name)
        return self.uri self.path(@keywords[:repositories], name)
      end
    end

    class Repository
      attr_reader :name, :scm, :ssh_href, :owner, :language

      def name=(new_name)
        if (new_name == nil)
          raise ArgumentError.new("Repository name cannot be nil")
        end
        @name = new_name
      end

      def scm=(new_scm)
        if (new_scm != nil && new_scm != 'git')
          raise ArgumentError.new("Only git is supported")
        else
          @scm = 'git'
        end
      end

      def owner=(new_owner)
        if (new_owner == nil)
          raise ArgumentError.new("Repository owner cannot be nil")
        end
        @owner = new_owner
      end

      def language=(new_language)
        if (new_language == nil)
          raise ArgumentError.new("Language cannot be nil")
        end
        @language = new_language
      end

      def ssh_href=(links)
        if (links == nil)
          raise ArgumentError.new("Unable get link for git repository from nil value")
        elsif (links && links.class == Array)
          link =links.select { |l| l["name"] == "ssh" }.first
          if (link["href"] == nil)
            raise ArgumentError.new("Unable to find link for git repository")
          end
        end
        @ssh_href =link['href']
      end

      def initialize(data)
        self.name       =data['name']
        self.scm        =data['scm']
        self.ssh_href   =data['links']['clone']
        self.owner      =data['owner']['username']
        self.language   =data['language']
      end
    end
  end
end