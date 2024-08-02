# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

before do
  @files = Dir.glob(File.join(data_path, "*")).map do |file_path|
    File.basename(file_path)
  end
end

def render_markdown(file_content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file_content)
end

def create_document(name, content = "")
  File.open(File.join(data_path, name), "w") do |file|
    file.write(content)
  end
end

def invalid_filename?(name)
  name.empty? || File.extname(name).empty?
end
  
get "/" do
  erb :index, layout: :layout
end

get "/users/login" do
  erb :login
end

post "/users/login" do
  username = params[:username]
  session[:username] = username if username == "admin"

  if username == "admin" && params[:password] == "secret"
    session[:message] = "Welcome!" 
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :login
  end
end

post "/users/logout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

get "/new" do
  erb :new, layout: :layout
end

post "/create" do
  file_name = params[:filename].strip
  error = invalid_filename?(file_name)
  
  if error
    session[:message] = "A valid name and extension is required."
    status 422
    erb :new
  else
    session[:message] = "#{file_name} was created."
    create_document(file_name)
    redirect "/"
  end
end

post "/:file_name" do
  file_path = File.join(data_path, "/#{params[:file_name]}")
  file_content = params[:content]

  File.write(file_path, file_content)

  session[:message] = "#{params[:file_name]} has been updated."
  redirect "/"
end

post "/:file_name/destroy" do
  file_path = File.join(data_path, "/#{params[:file_name]}")
  File.delete(file_path)
  session[:message] = "#{params[:file_name]} has been deleted."
  redirect "/"
end

get "/:file_name" do
  file_path = File.join(data_path, "/#{params[:file_name]}")
  file_ext = File.extname(params[:file_name])

  if File.file?(file_path)
    case file_ext
    when ".md" 
      erb render_markdown(File.read(file_path))
    when ".txt"
      headers["Content-Type"] = "text/plain"
      File.read(file_path)
    end
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
end

get "/:file_name/edit" do
  file_path = File.join(data_path, "/#{params[:file_name]}")

  @filename = params[:file_name]
  @content = File.read(file_path)
  
  erb :edit
end



