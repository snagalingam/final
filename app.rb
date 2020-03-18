# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "geocoder"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

awards_table = DB.from(:awards)
colleges_table = DB.from(:colleges)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

#### USER INFORMATION

# homepage displays the signup form (aka "new")
get "/" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    existing_user = users_table.where(email: params["email"]).to_a[0]

    if existing_user
      view "error"
    else
      users_table.insert(
          name: params["name"],
          email: params["email"],
          password: BCrypt::Password.create(params["password"])
      )

      session["user_id"] = users_table.where(email: params["email"]).to_a[0][:id]
      @current_user = users_table.where(id: session["user_id"]).to_a[0]
      @colleges = colleges_table
      view "colleges"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user && BCrypt::Password.new(@user[:password]) == params["password"]
      session["user_id"] = @user[:id]
      @current_user = users_table.where(id: session["user_id"]).to_a[0]
      @colleges = colleges_table
      view "colleges"
    else
        view "error"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/"
end

#### COLLEGE INFORMATION

# college details (aka "show")
get "/colleges/:id" do
    @college = colleges_table.where(id: params[:id]).to_a[0]

    location = @college[:city] + ", " + @college[:state]
    results = Geocoder.search(location)
    lat_long = results.first.coordinates
    @lat = lat_long[0]
    @long = lat_long[1]

    @award = awards_table.where(college_id: @college[:id]).where(user_id: session["user_id"]).to_a[0]

    view "college"
end


#### AWARD INFORMATION

# display the award form (aka "new")
get "/colleges/:id/awards/new" do
    @college = colleges_table.where(id: params[:id]).to_a[0]
    view "new_award"
end

# receive the submitted award form (aka "create")
post "/colleges/:id/awards/create" do
    @college = colleges_table.where(id: params[:id]).to_a[0]

    awards_table.insert(
        college_id: @college[:id],
        user_id: session["user_id"],
        grants: params["grants"],
        loans: params["loans"],
        work_study: params["work_study"]
    )

    @award = awards_table.where(college_id: @college[:id]).where(user_id: session["user_id"]).to_a[0]
    view "college"
end

# edit the submitted award form
get "/awards/:id/edit" do
    @award = awards_table.where(id: params["id"]).to_a[0]
    @college = colleges_table.where(id: @award[:college_id]).to_a[0]
    view "edit_award"
end

# update the data once edited
post "/awards/:id/update" do
    award = awards_table.where(id: params["id"]).to_a[0]
    @college = colleges_table.where(id: award[:college_id]).to_a[0]
    if @current_user && @current_user[:id] == award[:user_id]
      awards_table.where( id: award[:id]).update(
        grants: params["grants"],
        loans: params["loans"],
        work_study: params["work_study"]
      )

      @award = awards_table.where(id: params["id"]).to_a[0]
      view "college"
    else
      view "error"
    end
end

# destroy the submitted award form
get "/awards/:id/destroy" do
    award = awards_table.where(id: params["id"]).to_a[0]
    @college = colleges_table.where(id: award[:college_id]).to_a[0]
    awards_table.where(id: params["id"]).delete
    view "college"
end
