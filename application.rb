# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

root_path = File.expand_path("..", __FILE__)

before do
  @files = Dir.glob(root_path + "/data/*").map do |file_path|
    File.basename(file_path)
  end
end
  
get "/" do
  erb :index 
end

get "/:file_name" do
  file_path = root_path + "/data/#{params[:file_name]}"

  if File.file?(file_path) 
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
end
