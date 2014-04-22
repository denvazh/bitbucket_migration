require 'bitbucket_migration'

def get_full_path(path)
  return File.join(File.dirname(__FILE__), path)
end

def load_file(location)
  return File.new(location, 'r')
end