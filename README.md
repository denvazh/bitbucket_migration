# BitbucketMigration

Sequentially import repositories listed in csv file to bitbucket.

Note: this was created with goal to bulk import all existing repositories to bitbucket, i.e. it supposed to be one time task.

## Installation

Add this line to your application's Gemfile:

    gem 'bitbucket_migration'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bitbucket_migration

## Usage

In order to use this gem it is necessary to prepare the following:

YAML configuration file in the following format

	username: %bitbucket username%
	password: %password or API key (in case of team)%
	team: %optionally, if importing to team%

Repository list in csv format, where values have to be in the following order

	ssh link to repository, name repository will be created in bitbucket, programming language

For example, if importing from some remote repository first line of csv file would look like below:

	git@gitserver:proj/myrepo.git,myrepo,ruby

It is recommended to setup ssh access with private key authentication, thus it won't be necessary to
input password for every repository migration.

Lastly, starting migration to bitbucket:

	$ bitbucket_migration -c config.yml -l list.csv

## Contributing (following git-flow model)

0. Acknowledge, that in its current state code and tests require severe refactoring
1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## Running tests

1. Create configuration file and put it in `spec/data/config.yml`
2. Create csv file with valid repositories and put it in `spec/data/source_repositories.csv`
3. Run tests (`rake spec`)
4. Optionally to use guard to constantly execute tests, run (`guard`)

## Documentation

1. Clone it
2. Install required development dependencies (`bundle install`)
3. Generate documentation (`rake doc`)