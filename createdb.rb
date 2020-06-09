# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :attractions do
  primary_key :id
  String :title
  String :description, text: true
  String :location
  String :category
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :attraction_id
  foreign_key :user_id
  Boolean :recommend
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :mobile
  String :email
  String :password
end

# Insert initial (seed) data
attractions_table = DB.from(:attractions)

attractions_table.insert(title: "Singapore Botanic Garden", 
                    description: "Developed in 1859, the Gardens is the first and only tropical botanic garden on the UNESCO’s World Heritage List.",
                    location: "1 Cluny Road Singapore 259569",
                    category: "Nature")

attractions_table.insert(title: "National Museum of Singapore", 
                    description: "If you have time to visit only one place to learn about the history and culture of Singapore, this is probably it.",
                    location: "93 Stamford Road, Singapore 178897",
                    category: "History")