# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :college do
  primary_key :id
  String :name
  String :city
  String :state
  Integer :tuition_fees
  Integer :room_meals
end
DB.create_table! :cost do
  primary_key :id
  foreign_key :college_id
  foreign_key :user_id
  Integer :grants
  Integer :loans
  Integer :work_study
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
events_table = DB.from(:college)

events_table.insert(name: "University of Illinois at Urbana-Champaign",
                    city: "Champaign",
                    state: "IL",
                    tuition_fees: "21870",
                    room_meals: "12252")

events_table.insert(name: "DePaul University",
                    city: "Chicago",
                    state: "IL",
                    tuition_fees: "42468",
                    room_meals: "15093")
puts "Success!"
