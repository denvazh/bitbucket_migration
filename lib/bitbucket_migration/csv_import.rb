require 'csv'

module BitbucketMigration
  class CSVImport
    attr :repositories

      # Holds list of source repositories loaded from the csv file
      def initialize(csvfile)
        @repositories ||=[]
        raise ArgumentError, "Argument cannot be empty" unless !csvfile.nil?

        file = CSV.open(csvfile)
        file.each_with_index do |item|
          url         =item.shift
          name        =item.shift
          language    =item.shift

          repositories << GitRepository.new(url, name, language)
        end
      end
  end
end