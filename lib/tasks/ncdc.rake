require "erb"
include ERB::Util
require File.join(Rails.root, 'lib','csv_mappings.rb')

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

  #############################################
  # TODO: Extract to a wikidata client library
  #############################################


  WIKIBASE_URL = "http://172.104.209.93:8181/api.php"


  # return QCode of new item
  def create_item(label, description=nil)  
    url = WIKIBASE_URL
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
    url = WIKIBASE_URL

    value = value.strip
    if value.match(/^Q\d+/)
      value = { "entity-type" => "item", "numeric-id" => strip_q(value) }
    # elsif value.match(/^http/)
      # value = { "entity-type" => "url", "value" => { "url" => value} }      
    elsif value.match(/^c?\d\d\d\d\b/) && !value.match(/[a-zA-Z]{4,}/) 
      # this is a date
      value_hash = { "entity-type" => "time", "before" => 0, "after" => 0, "timezone" => 0, "calendarmodel" => PROLEPTIC_GREGORIAN }
      if value.match(/c\d\d\d\d/)
        # approximate year
        value_hash['precision'] = PRECISION_DECADE
        value_hash['time'] = "+0000000#{value.gsub(/\D/,'')}-00-00T00:00:00Z"
      elsif value.match(/\d\d\d\d-\d\d-\d\d/)
        # full date
        value_hash['precision'] = PRECISION_DAY
        value_hash['time'] = "+0000000#{value}T00:00:00Z"
      elsif value.match(/\d\d\d\d-\d\d/)
        # full date
        value_hash['precision'] = PRECISION_MONTH
        value_hash['time'] = "+0000000#{value}-00T00:00:00Z"
      else
        # year only (we hope)
        value_hash['precision'] = PRECISION_YEAR
        value_hash['time'] = "+0000000#{value}-00-00T00:00:00Z"
      end
      value = value_hash
    else
      # it's a string
      value = value.truncate(400)
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
    if hash["claim"].nil? || hash["claim"]["id"].nil?
      binding.pry
    end
    
    statement_id = hash["claim"]["id"]
    
    if contributing_project_qcode
      add_reference_to_claim(statement_id, contributing_project_qcode)
    end
    
    statement_id
  end

  CLAIMED_BY = 'p36'
  def add_reference_to_claim(statement_id, contributing_project_qcode)
    url = WIKIBASE_URL
    
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

  def delete_item(qcode)
    url = WIKIBASE_URL
    
    params = {:action=>"delete", :format=>"json", :title => "Item:#{qcode}", :token => "+\\"}

    resp = RestClient.post(url, params)
    hash = JSON.parse(resp.body)
    binding.pry
    qcode
  end
  
  def qcode(title)
    
  end
 
  #############################################
  # End extract to a wikidata client library
  #############################################

 
  
  ABBREVIATION_MAP = {
    "KY" => "Kentucky",
    "VA" => "Virginia",
    "TN" => "Tennessee",
    "MS" => "Mississippi",
    "NY" => "New York",
    "MA" => "Massachusetts",
    "NH" => "New Hampshire",
    "PA" => "Pennsylvania"
  }

  def clean_placename(placename)          # change strange formatting
    placename.gsub!("/", ", ")
    placename.gsub!(/^\s/, '')
    placename.gsub!(/\s$/, '')
    # default is USA; eliminate
    placename.gsub!(", USA", '')
    placename.gsub!("/", ", ")      

    if ABBREVIATION_MAP[placename]
      placename = ABBREVIATION_MAP[placename]
    end
    placename
  end
  
  desc "get places from csv"
  task places_from_csv: :environment do
    p "These items have been created already -- exiting"
    exit
    
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
      clean_placename(placename)
    end
    
    clean_places.uniq.each do |placename|      # create item
      qcode = create_item(placename)
      
      print "\"#{placename}\" => \"#{qcode}\",\n"
    end
  end

  def key(header)
    header.upcase.gsub(/\s/, '_')
  end

  desc "insert people"
  task insert_people: :environment do
    csv_array = load_csv

    csv_array.each do |row|
      # find the member edition
      raw_edition = row[PUBLISHER]
      # map the member edition
      edition_qcode = CSV_MAP[key(PUBLISHER)][:value_map][raw_edition]

      label = label(row[FULLNAME], row[SUFFIX])
      # insert the record
      print "qcode = create_item(#{label}, #{label})\n"
      qcode = create_item(label, label)
#      qcode = "Q#{label}"

      # now add the properties
      
      # hard-code  "instance-of" "human"
      print "edit_item(#{qcode}, P33, Q90, #{edition_qcode}) # instance_of human \n"                          
      edit_item(qcode, 'P33', 'Q90', edition_qcode) # instance_of human \n"                          
      csv_array.headers.each do |header|
        # is this a cell to enter?
        if CSV_MAP[key(header)]
          # figure out the P-code
          pcode = CSV_MAP[key(header)][:pcode]
          if pcode
            value = row[header]
            if value
              # handle ugly place names
              if [STATE_COUNTRY_OF_BIRTH, STATE_COUNTRY_OF_DEATH].include?(header)
                value = clean_placename(value)
              end
              # figure out the value
              if CSV_MAP[key(header)][:value_map]
                value = CSV_MAP[key(header)][:value_map][value] || value
              end
              # add the property
  #            edit_item(qcode, pcode, value, edition_qcode)            
              print "edit_item(#{qcode}, #{pcode}, #{value}, #{edition_qcode}) # #{header}\n"                          
              edit_item(qcode, pcode, value, edition_qcode)                           
            end
          end        
        end
      end

      # special parameters
      #urls
      url = row[URL]
      if url
        # special processing for PAL URL
        if edition_qcode == PAL_QCODE
          print "edit_item(#{qcode}, P25, #{url}, #{edition_qcode})\n"                                    
          edit_item(qcode, 'P25', url, edition_qcode)                                    
        end
        # special processing for CWGK URL
        if edition_qcode == KHS_QCODE
          print "edit_item(#{qcode}, P24, #{url}, #{edition_qcode})\n"                                              
          edit_item(qcode, 'P24', url, edition_qcode)                                              
        end
      end

      # special processing for text location thingy
      pub_details = []
      pub_details << row[PUBLICATION] if row[PUBLICATION]
      pub_details << "Series #{row[SERIES]}" if row[SERIES]
      pub_details << "Volume #{row[VOLUME]}" if row[VOLUME]
      pub_details << "Book #{row[BOOK]}" if row[BOOK]
      pub_details << "Page #{row[PAGE]}" if row[PAGE]
      pub_details << "Note #{row[NOTE]}" if row[NOTE]
      unless pub_details.empty?
        print "edit_item(#{qcode}, P38, '#{pub_details.join(', ')}', #{edition_qcode})\n"                                              
        edit_item(qcode, 'P38', pub_details.join(', '), edition_qcode)                                              
      end    
      
      # special processing for biography
      fragment = label_to_url_fragment(label)
      bio = "http://172.104.209.93:8181/wiki/#{fragment}"
      print "edit_item(#{qcode}, P32, #{bio}, #{edition_qcode})\n"                                              
      edit_item(qcode, 'P32', bio, edition_qcode)                                                 
      print "\t\t\"#{label}\" => \"#{qcode}\"  #GREP\n"
    end
  end



  desc "exercise API on our wikidata"
  task test_api: :environment do
    qcode = create_item("Test Item #{Time.now}", "A nice peach cobbler")
    edit_item(qcode, 'P28', "Smith", 'Q16')
    edit_item(qcode, 'P13', "Q11", 'Q16')   
    # dates to be dealt with:
    # 1907
    edit_item(qcode, 'P8', '1907', 'Q16')
    # 1869-11-20
    edit_item(qcode, 'P8', '1869-11-20', 'Q16')
    # c1800
    edit_item(qcode, 'P8', 'c1824', 'Q16')
    edit_item(qcode, 'P32', 'http://172.104.209.93:8181/wiki/George_Barrell_Cheever')    
    delete_item(qcode)    
    p qcode
  end

  desc "print curl commands to create pages for biographies"
  task bios_from_csv: :environment do
    csv_array = load_csv
    csv_array.each do |row|
      fullname  = label(row[FULLNAME], row[SUFFIX])
      fullname = label_to_url_fragment(fullname)
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
  
  def label(fullname, suffix)
    fullname = fullname + " " + suffix if suffix
    fullname
  end  
  
  def label_to_url_fragment(label)
    label.squish.tr(" ","_")    
  end
  def load_csv
    CSV.read(FILENAME, :headers => true)    
  end

end
