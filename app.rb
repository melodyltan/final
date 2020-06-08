# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

attractions_table = DB.from(:attractions)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all tourist attractions)
get "/" do
    @attractions = attractions_table.all
    view "attractions"
end

# Show a single attraction
get "/attractions/:id" do
    @users_table = users_table
    # SELECT * FROM attractions WHERE id=:id
    @attraction = attractions_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM reviews WHERE attraction_id=:id
    @reviews = reviews_table.where(:attraction_id => params["id"]).to_a
    # SELECT COUNT(*) FROM reviews WHERE attraction_id=:id AND recommend=1
    @count_recommend = reviews_table.where(:attraction_id => params["id"], :recommend => true).count
    results = Geocoder.search(@attraction[:location])
    @lat_long = results.first.coordinates.join(",")
    view "attraction"
end

# Form to create a new review
get "/attractions/:id/reviews/new" do
    @attraction = attractions_table.where(:id => params["id"]).to_a[0]
    view "new_review"
end

# Receiving end of new review form
post "/attractions/:id/reviews/create" do
    reviews_table.insert(:attraction_id => params["id"],
                       :recommend => params["recommend"],
                       :user_id => @current_user[:id],
                       :comments => params["comments"])
    @attraction = attractions_table.where(:id => params["id"]).to_a[0]
    view "create_review"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
    # read your API credentials from environment variables
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]
    # set up a client to talk to the Twilio REST API
    client = Twilio::REST::Client.new(account_sid, auth_token)
    # send the SMS from your trial Twilio number to your verified non-Twilio number
    client.messages.create(from: "+12012988938", 
                           to: "+18728066437",
                           body: "Welcome to See Singapore! For more information on any tourist attraction, call the See Singapore hotline: (+65) 1122 8899. Our service team is available from 9AM-5PM everyday.")    
                       view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    
    # Step 1: Test for valid email
    if user 
        puts user.inspect
        # Step 2: Test the password_entered
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
        view "create_login"
        else
        view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end