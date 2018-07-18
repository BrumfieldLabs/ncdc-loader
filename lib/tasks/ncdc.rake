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


  URL = "http://172.104.209.93:8181/api.php"

  # return QCode of new item
  def create_item(label, description=nil)  
    url = URL
    params = {:action=>"wbeditentity", :format=>"json", :new => 'item', :token => "+\\"}
    data = {}
    data[:labels] = [{:language=>'en', 'value'=>label}]
    data[:descriptions] = [{:language=>'en', 'value'=>description}] unless description.blank? 

    params[:data]=data.to_json
    resp = RestClient.post(url, params)
    hash = JSON.parse(resp.body)

    hash["entity"]["id"]
  end

  def strip_q(qcode)
    qcode.sub(/\D/,'')
  end

  PROLEPTIC_GREGORIAN = 'http://www.wikidata.org/entity/Q1985727'
  PRECISION_DAY = 11
  PRECISION_MONTH = 10
  PRECISION_YEAR = 9
  PRECISION_DECADE = 8


  # return a claim ID
  def edit_item(qcode, property, value, contributing_project_qcode=nil)
    url = URL

    if value.match(/Q\d+/)
      value = { "entity-type" => "item", "numeric-id" => strip_q(value) }
    elsif value.match(/c?\d\d\d\d/)
      # this is a date
#      value_hash = { "entity-type" => "time", "timezone" => 0, "calendarmodel" => PROLEPTIC_GREGORIAN }
      value_hash = { "entity-type" => "time", "before" => 0, "after" => 0, "timezone" => 0, "calendarmodel" => PROLEPTIC_GREGORIAN }
#      value_hash = { "entity-type" => "time", "before" => 0, "after" => 0, "timezone" => 0 }
      if value.match(/c\d\d\d\d/)
        # approximate year
        value_hash['precision'] = PRECISION_DECADE
        value_hash['time'] = "+0000000#{value.gsub(/\D/,'')}-00-00T00:00:00Z"
      elsif value.match(/\d\d\d\d-\d\d-\d\d/)
        # full date
        value_hash['precision'] = PRECISION_DAY
        value_hash['time'] = "+0000000#{value}T00:00:00Z"
      else
        # year only (we hope)
        value_hash['precision'] = PRECISION_YEAR
        value_hash['time'] = "+0000000#{value}-00-00T00:00:00Z"
      end
      value = value_hash
    end

    params = 
    { :action=>"wbcreateclaim", 
      :entity => qcode, 
      :property => property, 
      :value => value.to_json, 
      :snaktype => 'value',
      :format=>"json", 
      :bot => 1, 
      :token => "+\\"}
    resp = RestClient.post(url, params)    
    hash = JSON.parse(resp.body)
    statement_id = hash["claim"]["id"]
    
    if contributing_project_qcode
      add_reference_to_claim(statement_id, contributing_project_qcode)
    end
    
    statement_id
  end

  CLAIMED_BY = 'p36'
  def add_reference_to_claim(statement_id, contributing_project_qcode)
    url = URL
    
    snaks = 
    { CLAIMED_BY => [
      :snaktype => 'value',
      :property => CLAIMED_BY,
      :datavalue => {
        :type => 'wikibase-entityid',
        :value => {
          'entity-type' => 'item',
          'numeric-id' => strip_q(contributing_project_qcode)
        }
      }
    ]}
    
    params = 
    { :action=>"wbsetreference", 
      :statement => statement_id, 
      :snaks => snaks.to_json,
      :format=>"json", 
      :bot => 1, 
      :token => "+\\"}
    resp = RestClient.post(url, params)    

    hash = JSON.parse(resp.body)
    
    hash

  end

  
  desc "get places from csv"
  task places_from_csv: :environment do
    csv_array = load_csv
     
    # read the places from the file
    places = []
    csv_array.each do |row|
      birth_place  = row[STATE_COUNTRY_OF_BIRTH] 
      places << birth_place if birth_place
      death_place  = row[STATE_COUNTRY_OF_DEATH]
      places << death_place if death_place       
    end
    
    # clean the entries
    clean_places = places.map do |placename|
      # change strange formatting
      placename.gsub!("/", ", ")
      placename.gsub!(/^\s/, '')
      placename.gsub!(/\s$/, '')
      # default is USA; eliminate
      placename.gsub!(", USA", '')
      placename.gsub!("/", ", ")      
      
      placename
    end
    
    clean_places.uniq.each do |placename|
      p placename
    end
    
    qcode = create_item("Test Item #{Time.now}", "A nice peach cobbler")
    edit_item(qcode, 'P28', "Smith", 'Q16')
    edit_item(qcode, 'P13', "Q11", 'Q16')
    
    # dates to be dealt with:
    # 1907
    edit_item(qcode, 'P8', '1907')
    # 1869-11-20
    edit_item(qcode, 'P8', '1869-11-20')
    # c1800
    edit_item(qcode, 'P8', 'c1824')
    
    
    p qcode
    
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
