
require 'sinatra'
require 'sinatra/reloader' if development?
Dir.glob("libraries/**/*.rb").each do |file|
    also_reload file
end
require 'securerandom'
require_relative './libraries/laboratoire.rb'

SHA_KEY = "j9wh-LdCCM_2eaL@1VDP#MSLqp$Nn?W9OX&V9L?H"

include Laboratoire

helpers do
    def guard!
        auth_required = [
          401,
          {
            "WWW-Authenticate" => "Basic"
          },
          "Provide a username and password"
        ]
    
        halt auth_required unless authorized?
    end
  
    def authorized?
        @auth ||= Rack::Auth::Basic::Request.new(request.env)

        return false unless @auth.provided? && @auth.basic? && @auth.credentials

        username, password = @auth.credentials

        @user = JSON.parse(Laboratoire::Auth::login(username, password))[0]

        return false if @user.nil?

        return @user
    end
end

get '/login' do
    guard!

    redirect '/'
end

get '/' do
    send_file('gallery.html')
end

##List
get '/files' do    
    authorized?
    Laboratoire::Files::list_all("files", @user)
end

##Get a specific file
get '/files/:hash' do
    authorized?

    response = Laboratoire::Files::list_one("files", params["hash"], params["pass"], @user)
    
    send_file(response[1]) unless response[0].to_s.include?("40")

    return response[1]
end

##Create a new file
post "/files" do 
    guard!
    
    response = Laboratoire::Files::create(@user, JSON.parse(params["options"]), params["file_password"], params["file"])
    
    return [response[0], {"Content-Location" => response[1].map {|item| item.delete_prefix(".").delete_suffix(".txt")} }, response[1]]
end

##Modify a file
patch '/files/:hash' do
    guard!

    response = Laboratoire::Files::modify("files", params["hash"], @user, request.body.read)

    return response
end

##Delete a file
delete '/files/:hash' do
    guard!

    response = Laboratoire::Files::destroy("files", params["hash"], @user)

    return response
end
