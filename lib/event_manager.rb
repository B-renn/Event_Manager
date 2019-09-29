#requires the following libs
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

#clean_zipcode takes zipcodes from csv file and creates proper 5-digit zipcodes
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

#Uses google's Civic API with zipcode extracted from csv file
def legislators_by_zipcode(zip)
  #creates variable using google's Civic API and key=AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw : A registered API Key to authenticate our requests -- read more about google's civic API @ https://github.com/googleapis/google-api-ruby-client
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  #uses API's built in method to get civic information. The method is passed the zipcode extracted from csv file. Levels and roles are generic requriments for the API. levels=country : The level of government we want to select | roles=legislatorUpperBody : Return the representatives from the Senate | roles=legislatorLowerBody : Returns the representatives from the House
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  #If the API is passed an invalid zipcode, this will rescue the and print the following statment  
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

#Method to save thank you letters for everyone is the CSV file
def save_thank_you_letters(name,form_letter)
  #Creates output directory
  Dir.mkdir("output") unless Dir.exist? "output"
  #Creates file in the output directory for each person in CSV file
  filename = "output/thanks_#{name}.html"
  #Opens file created above and puts the thank you letter in that file
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."
#Reads input from CSV file and template html (erb) file
contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
#creates erb template from input erb file
erb_template = ERB.new template_letter

#Loops through CSV file - extracts name and zipcode for each entry (row) --> then passes the information in the methods at the top of the file
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  #this will pass the vars name and legislators into the erb file
  form_letter = erb_template.result(binding)
  save_thank_you_letters(name,form_letter)
end