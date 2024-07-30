# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erubis'
require 'redcarpet'

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

def render_markdown(file_content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file_content)
end

get "/:file_name" do
  file_path = root_path + "/data/#{params[:file_name]}"
  file_ext = File.extname(params[:file_name])

  if File.file?(file_path)
    case file_ext
    when ".md" 
      render_markdown(File.read(file_path))
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
  file_path = root_path + "/data/#{params[:file_name]}"

  @filename = params[:file_name]
  @content = File.read(file_path)
  
  erb :edit
end

post "/:file_name" do
  file_path = root_path + "/data/#{params[:file_name]}"
  file_content = params[:content]

  File.write(file_path, file_content)

  session[:message] = "#{params[:file_name]} has been updated."
  redirect "/"
end
