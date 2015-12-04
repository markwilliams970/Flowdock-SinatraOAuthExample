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

# Re-direct URL
APP_REDIRECT_URL = "http://localhost:4567/flowdock-oauth-redirect"

enable :sessions

get '/login' do
	uri = URI(FD_ACCESS_URL)
	params = {
		:state => SecureRandom.uuid, # a random number used to validate the request received when Flowdock redirects back
		:response_type => "code", # We want an authentication token, known as code.
		:redirect_uri => APP_REDIRECT_URL, # This must match the redirect uri specified when creating your client
		:client_id => CLIENT_ID # This is issued by Flowdock when you create your client
	}
	session[:state] = params[:state]

	uri.query = URI.encode_www_form(params)
	redirect to(uri.to_s)
end


get '/flowdock-oauth-redirect' do
	if params[:state] != session[:state]
		return "Invalid State"
	elsif params[:error] != nil
		return "Error with authorization #{params[:error]}"
	end

	# Now exchance access code for a Bearer token
	new_params = {
		:code => params[:code], # the authentication token supplied by rally in the redirect
		:redirect_uri => APP_REDIRECT_URL, # must match the redirect specified earlier
		:grant_type => "authorization_code", # we are supplying an authorization token to exchange for an access token
		:client_id => CLIENT_ID, # The Client ID you got from creating a Rally OAuth Client
		:client_secret => CLIENT_SECRET # The Client Secret you got from creating a Rally OAuth Client

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

    # Try posting a simple message to the first flow in our list
    main_flow = list_of_flows.first

    # Construct authenticated Flow URL
    flow_url = main_flow["url"]
    flow_url_split = flow_url.split("/")
    flow_path = flow_url_split[-3, 3].join("/")
    flow_token = main_flow["api_token"]

    flow_messages_url = "https://api.flowdock.com/#{flow_path}/messages"
    post_body = {
    	"event": "message",
    	"content": "Hi @team!"
    }

    begin
     	message_resp = RestClient.post flow_messages_url, post_body.to_json, :authorization => "Bearer #{session[:auth]}", :content_type => "application/json", :accept => :json
     	response_json = JSON.load(message_resp)
    rescue Exception => e
     	return "Failed to post message: #{e.to_s}"
     end

	erb :index, :locals => { :flows => list_of_flows, :bearer_token => session[:auth] }

end

get '/logout' do
	session[:auth] = nil
	"Logged Out"
end