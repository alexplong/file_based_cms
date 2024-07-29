# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

before do
  @root_path = File.expand_path("..", __FILE__)

  @files = Dir.glob(@root_path + "/data/*").map do |file_path|
    File.basename(file_path)
  end

  @messages ||= {}
end

def valid_file?(file_name)
  @files.include? file_name ? false : true    
end


get "/" do
  erb :layout 
end

get "/:file_name" do
  file_name = params[:file_name]

  error = valid_file?(file_name)

  if error
    @messages[:error] = "#{file_name} does not exist."
    redirect "/"
  else
    file_path = @root_path + "/data/#{file_name}"
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  end
end
