namespace :properties do
  desc "Display properties from dumpfile"
  task :print_export, [:pathname] => :environment  do  |t,args|
    json = JSON.parse(File.read(args.pathname))
#    binding.pry
    print "ID\tLABEL\tDATATYPE\tDESCRIPTION\tEXAMPLE\n"
    json.each do |property|
      csv = []
      csv << property["id"]
      csv << property["label"]
      csv << property["datatype"]
      csv << property["description"]
      if property["example"] && example = property["example"].first
        csv << "https://www.wikidata.org/wiki/Q#{example}"
      end
      print csv.join("\t")
      print "\n"
    end
    
#    p 'foo'
    
  end
end
