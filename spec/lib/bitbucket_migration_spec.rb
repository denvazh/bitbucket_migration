require 'spec_helper'

describe BitbucketMigration do

  # Required static files
  # Note: paths set relative to path of spec_helper
  data        =get_full_path('/data/source_repositories.csv')
  configfile  =get_full_path('data/config.yml')
  bitbucket_response_sample = get_full_path('data/bitbucket_response.json')

	it "should return current version number" do
		version = BitbucketMigration::VERSION
		version.should_not be_nil
		version.split('.').size.should == 3
	end

  it "should have valid model for local git repository" do
    url = 'ssh://git@git.test:test.git'
    name = 'test_repo'
    language = 'ruby'

    gitrepo = BitbucketMigration::GitRepository.new(url, name, language)
    gitrepo.should_not be_nil
    gitrepo.url.should == url
    gitrepo.name.should == name
    gitrepo.language.should == language
    expect { gitrepo.url=nil }.to raise_error(ArgumentError)
    expect { gitrepo.name=nil }.to raise_error(ArgumentError)
  end

  it "should read csv file and return array of GitRepository objects" do
    csv   =BitbucketMigration::CSVImport.new(data)
    expect {BitbucketMigration::CSVImport.new(nil)}.to raise_error(ArgumentError)
    csv.repositories.should_not be_nil
    csv.repositories.size.should_not == 0
    csv.repositories.class.should == Array
    csv.repositories[rand(csv.repositories.size - 1)].class.should == BitbucketMigration::GitRepository
  end

  it "should be possible to load configuration from file" do
    config = BitbucketMigration::Configuration.new(configfile)
    config.username.should_not be_nil
    config.password.should_not be_nil
  end

  it "should be possible to create and delete temporary working directory" do
    workdir = BitbucketMigration::WorkDir.new
    Dir.exists?(workdir.path).should == true
    workdir.clean
    workdir.path.should be_nil
  end

  #
  # Bitbucket API related tests
  #
  it "should return valid endpoint for given parameters and requests" do
    user = 'testuser'
    pass = 'testpass'
    team = 'testteam'
    repo = 'testrepo'
    endpoint = BitbucketMigration::Api::Endpoint.new(user, pass, team)
    endpoint.repositories.should == "https://#{user}:#{pass}@bitbucket.org/api/2.0/repositories/#{team}"
    endpoint.repository(repo).should == "https://#{user}:#{pass}@bitbucket.org/api/2.0/repositories/#{team}/#{repo}"
  end

  it "should use username if team is nil" do
    user = 'testuser'
    pass = 'testpass'
    team = nil
    endpoint = BitbucketMigration::Api::Endpoint.new(user, pass, team)
    endpoint.repositories.should == "https://#{user}:#{pass}@bitbucket.org/api/2.0/repositories/#{user}"
  end

  # Using local json file with content exactly matching response from bitbucket
  it "should have valid model for bitbucket api repository" do
    data_sample = JSON.load(load_file(bitbucket_response_sample))
    sample_repo = BitbucketMigration::Api::Repository.new(data_sample['values'].last)
    sample_repo.name.should == 'domain_sync'
    sample_repo.scm.should == 'git'
    sample_repo.ssh_href.should == 'ssh://git@bitbucket.org/denis_vazhenin/domain_sync.git'
    sample_repo.owner.should == 'denis_vazhenin'
    sample_repo.language.should == 'ruby'
  end

  it "should be possible to get list of respositories in bitbucket" do
    config = BitbucketMigration::Configuration.new(configfile)
    bitbucket = BitbucketMigration::Api.new(config.username, config.password, config.team)
    repos = bitbucket.get_repositories
    repos.should_not be_nil
    repos['values'].class.should == Array
    repos['values'].size.should > 0
  end

  # Assuming repository doesn't exists
  it "should be possible to check if repository doesn't exists in the bitbucket" do
    csv     =BitbucketMigration::CSVImport.new(data)
    repo    =csv.repositories.first
    config  =BitbucketMigration::Configuration.new(configfile)
    bitbucket   =BitbucketMigration::Api.new(config.username, config.password, config.team)
    bitbucket.repository_exists?(repo.name).should == false
  end

  #
  # Below tests should be executed in order they appear, otherwise it might lead to strange outcome
  #

  it "should be possible to create repository in bitbucket" do
    csv     =BitbucketMigration::CSVImport.new(data)
    repo    =csv.repositories.first
    config  =BitbucketMigration::Configuration.new(configfile)
    bitbucket   =BitbucketMigration::Api.new(config.username, config.password, config.team)
    new_repo    =bitbucket.create_repository(repo.name, repo.language)
    new_repo.class.should ==BitbucketMigration::Api::Repository
    repo.name.should ==new_repo.name
    bitbucket.repository_exists?(repo.name).should == true
  end

  it "should be possible to clone git repository" do
    csv       =BitbucketMigration::CSVImport.new(data)
    config    =BitbucketMigration::Configuration.new(configfile)
    src_repo  =csv.repositories.first
    workdir   =BitbucketMigration::WorkDir.new
    bitbucket     =BitbucketMigration::Api.new(config.username, config.password, config.team)
    target_repo   =bitbucket.get_repository(src_repo.name)
    @gitinterface =BitbucketMigration::GitInterface.new(src_repo, target_repo)
    @gitinterface.init_src_repo(workdir.path)
    @gitinterface.git.should_not be_nil

    workdir.clean!
  end

  it "should be possible to fetch all existing branches of repository" do
    csv       =BitbucketMigration::CSVImport.new(data)
    config    =BitbucketMigration::Configuration.new(configfile)
    src_repo  =csv.repositories.first
    workdir   =BitbucketMigration::WorkDir.new
    bitbucket     =BitbucketMigration::Api.new(config.username, config.password, config.team)
    target_repo   =bitbucket.get_repository(src_repo.name)
    @gitinterface =BitbucketMigration::GitInterface.new(src_repo, target_repo)
    @gitinterface.init_src_repo(workdir.path)
    @gitinterface.fetch_src_repo_all

    workdir.clean!
  end

  it "should be possible to add remote repository reference and push code there" do
    csv       =BitbucketMigration::CSVImport.new(data)
    config    =BitbucketMigration::Configuration.new(configfile)
    src_repo  =csv.repositories.first
    workdir   =BitbucketMigration::WorkDir.new
    bitbucket     =BitbucketMigration::Api.new(config.username, config.password, config.team)
    target_repo   =bitbucket.get_repository(src_repo.name)
    @gitinterface =BitbucketMigration::GitInterface.new(src_repo, target_repo)
    @gitinterface.init_src_repo(workdir.path)
    @gitinterface.init_target_repo
    @gitinterface.fetch_src_repo_all
    @gitinterface.push_target_repo_all

    workdir.clean!
  end

    # Delete bitbucket repository
  it "should be possible to delete repository in bitbucket" do
    csv     =BitbucketMigration::CSVImport.new(data)
    repo    =csv.repositories.first
    config  =BitbucketMigration::Configuration.new(configfile)
    bitbucket   =BitbucketMigration::Api.new(config.username, config.password, config.team)
    if (bitbucket.repository_exists?(repo.name))
      bitbucket.delete_repository(repo.name).should == true
      bitbucket.repository_exists?(repo.name).should == false
    else
      bitbucket.delete_repository(repo.name).should == false
    end
  end

end
