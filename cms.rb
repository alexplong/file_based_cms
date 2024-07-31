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
  
get "/" do
  erb :index, layout: :layout
end

def render_markdown(file_content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file_content)
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

post "/:file_name" do
  file_path = File.join(data_path, "/#{params[:file_name]}")
  file_content = params[:content]

  File.write(file_path, file_content)

  session[:message] = "#{params[:file_name]} has been updated."
  redirect "/"
end
