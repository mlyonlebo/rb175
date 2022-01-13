require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  @chapters = File.readlines("data/toc.txt")
  erb :home
end

get "/chapters/1" do
  @title = "Chapter 1"
  @chapters = File.readlines("data/toc.txt")
  @chapter_one = File.read("data/chp1.txt")
  @paragraphs = @chapter_one.split("\n\n")  
  
  erb :chapter_one
end