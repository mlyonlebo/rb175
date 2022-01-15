require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do

  def in_numbered_paragraphs(chapter)
    id_count = 0
    chapter.split("\n\n").map do |graf|
      id_count += 1
      "<p id='#{id_count.to_s}'>#{graf}</p>"
    end.join
  end

  def bold_match(graf, query)
    strong_query = "<strong>#{query}</strong>"
    graf.gsub(query, strong_query)
  end

  def search_results(chapters, query)
    results = Hash.new([])
    chapters.each_with_index do |chapter, ch_idx|
      File.read(chapter).split("\n\n").each_with_index do |graf, p_idx|
        if graf.include?(query)
          graf = bold_match(graf, query)
          results[@contents[ch_idx]] += ["<li><a href=" + "/chapters/#{ch_idx+1}##{p_idx+1}" + ">#{graf}</a></li>"]
        end
      end
    end
    results
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  @chap_num = params['number']
  @title = @contents[@chap_num.to_i - 1]
  redirect "/" unless (1..@contents.size).cover?(@chap_num.to_i)

  @chapter = File.read("data/chp#{@chap_num}.txt")
  
  erb :chapter

end

get "/search" do
  @query = params[:query]
  @chapters = Dir.glob("data/*")

  erb :search
end

not_found do
  redirect "/"
end
