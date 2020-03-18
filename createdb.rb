# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :colleges do
  primary_key :id
  String :name
  String :city
  String :state
  Integer :tuition_fees
  Integer :room_meals
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
  String :phone
end
DB.create_table! :awards do
  primary_key :id
  foreign_key :college_id
  foreign_key :user_id
  Integer :grants
  Integer :loans
  Integer :work_study
end


# Insert initial (seed) data
colleges_table = DB.from(:colleges)

colleges_table.insert(name: "University of Illinois at Urbana-Champaign",
                    city: "Champaign",
                    state: "IL",
                    tuition_fees: "21870",
                    room_meals: "12252")

colleges_table.insert(name: "DePaul University",
                    city: "Chicago",
                    state: "IL",
                    tuition_fees: "42468",
                    room_meals: "15093")
puts "Success!"
