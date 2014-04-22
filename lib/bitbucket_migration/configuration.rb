require 'yaml'

module BitbucketMigration
  class Configuration
    DEFAULT_CONFIG='config.yml'

    attr_reader :file, :username, :password, :team

    def initialize(configfile)
      config = read(configfile)

      if(valid?(config))
        @file = configfile
        @username =config['username']
        @password =config['password']
        @team     =config['team']
      end
    end

    # Read configuration file 
    def read(configfile=nil)
      file = configfile ? configfile : DEFAULT_CONFIG
      begin
        conf = YAML::load_file(file)
        return conf
      rescue
        puts "[Error] " + $!.to_s
        exit
      end
    end

    # Check if configuration file has required keys and values
    def valid?(yml)
      expected = ['username','password','team']

      # check if required keys present
      valid_keys = expected.all? { |e| yml.keys.include?(e) }

      # check if values exists and not nil
      valid_values = yml.all? { |k,v| v.nil? || v.empty? || v.size == 0 }

      return valid_keys || valid_values ? true : false
    end

  end
end
