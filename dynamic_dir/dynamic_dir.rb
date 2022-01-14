require 'sinatra'
require 'sinatra/reloader'
#require 'tilt/erubis'

get "/" do
  order = params['order']
  @index = Dir.glob("public/*").map { |file| File.basename(file) }.sort
  if order == 'descending' 
    @index.reverse!
  end
  erb :home
end

get "/public/1.txt" do
  send_file 'public/1.txt'
end

get "/public/2.txt" do
  send_file 'public/2.txt'
end

get "/public/3.txt" do
  send_file 'public/3.txt'
end