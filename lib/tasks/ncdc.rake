require "erb"
include ERB::Util

namespace :ncdc do
  FILENAME = File.join(Rails.root, 'data', 'ncdc_form_responses.csv')
  
  # CSV Headers
  TIMESTAMP = "Timestamp"
  PUBLISHER = "Publisher"
  PUBLICATION = "Publication"
  SERIES = "Series"
  VOLUME = "Volume"
  BOOK = "Book"
  PAGE = "Page"
  NOTE = "Note"
  URL = "URL"
  SURNAME = "Surname"
  FORENAME = "Forename"
  TRIMMED_FORENAME = "trimmed forename"
  MIDDLE_NAME_INITIAL = "Middle Name/Initial"
  ALTERNATE_NAME = "Alternate Name"
  SUFFIX = "Suffix"
  THREE_PART_FULLNAME = "3 part fullname"
  TWO_PART_FULLNAME = "2 part fullname"
  FULLNAME = "fullname"
  SNAC_ID = "SNAC ID"
  SEX = "Sex"
  RACE_DESCRIPTION = "Race Description"
  BIRTH_DATE = "Birth Date"
  DEATH_DATE = "Death Date"
  STATE_COUNTRY_OF_BIRTH = "State/Country of Birth"
  STATE_COUNTRY_OF_DEATH = "State/Country of Death"
  BIOGRAPHY = "Biography"
  CITATION = "Citation"

  
  
  desc "get places from csv"
  task places_from_csv: :environment do
    csv_array = load_csv
    csv_array.each do |row|
      birth_place  = row[STATE_COUNTRY_OF_BIRTH] 
      p birth_place if birth_place
    end
  end

  desc "print curl commands to create pages for biographies"
  task bios_from_csv: :environment do
    csv_array = load_csv
    csv_array.each do |row|
      fullname  = row[FULLNAME]
      #add suffix if it exists 
      fullname = fullname + " " + row[SUFFIX] if row[SUFFIX]
      #replace spaces with _
      fullname = fullname.squish.tr(" ","_")
      biography = url_encode(row[BIOGRAPHY])
      #url encode biography
      #construct api url
      curl_arguments = "\"action=edit&title=#{fullname}&text=#{biography}&token=%2B%5C\""
      #print the curl command with the api url 
      curl_command = "curl -d #{curl_arguments} -X POST http://172.104.209.93:8181/api.php"
      puts curl_command
      # p fullname if fullname
      #p suffix if suffix
      #p biography if biography
    end
  end
  
  
  def load_csv
    CSV.read(FILENAME, :headers => true)
    
  end

end
