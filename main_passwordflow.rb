require 'sinatra'
require 'rest_client'

require 'net/http'
require 'securerandom'
require 'json'

RestClient.log = $stdout

# You can get your Client ID and Secret from:
# https://www.flowdock.com/oauth/applications
# The SERVER_URL must match the one specifed in Flowdock
CLIENT_ID = ENV["CLIENT_ID"]
CLIENT_SECRET = ENV["CLIENT_SECRET"]
SERVER_URL = ENV["SERVER_URL"] || "http://localhost:4567"

# Flowdock URLs
FD_URL = "https://api.flowdock.com"
FD_TOKEN_URL = "#{FD_URL}/oauth/token"
FD_ACCESS_URL = "#{FD_URL}/oauth/authorize"

# Username/Password for Password flow
FD_USERNAME = ENV["FD_USERNAME"]
FD_PASSWORD = ENV["FD_PASSWORD"]

# Re-direct URL
APP_REDIRECT_URL = "#{SERVER_URL}/flowdock-oauth-redirect"

enable :sessions

get '/login' do
    uri = URI(FD_TOKEN_URL)
    # Now exchance access code for a Bearer token
    new_params = {
        :client_id => CLIENT_ID, # The Client ID you got from creating a Flowdock OAuth Client
        :client_secret => CLIENT_SECRET, # The Client Secret you got from creating a Flowdock OAuth Client
        :grant_type => "password", # we are supplying an authorization token to exchange for an access token
        :username => FD_USERNAME,
        :password => FD_PASSWORD,
        :scope => "flow"
    }

    # post to FD_TOKEN_URL, the body is form-urlencoded
    # the client id and secret can also be sent as basic-auth
    begin
        access_resp = RestClient.post FD_TOKEN_URL, URI.encode_www_form(new_params), :content_type => "application/x-www-form-urlencoded", :accept => :json
    rescue Exception => e
        return "Failed to get Token #{e}"
    end

    session[:auth] = JSON.load(access_resp)["access_token"]
    session[:state] = nil

    redirect to('/')
end

get '/' do
    if session[:auth].nil?
        redirect to('/login')
    end
    list_of_flows = []

    flows_url = "#{FD_URL}/flows"

    # Lookup our available flows
    flows_resp = JSON.load(RestClient.get flows_url,  { "Authorization" => "Bearer #{session[:auth]}" })
    flows_resp.each { | this_flow |
        list_of_flows << this_flow
    }
    erb :index, :locals => { :flows => list_of_flows, :bearer_token => session[:auth] }

end

get '/logout' do
    session[:auth] = nil
    "Logged Out"
end