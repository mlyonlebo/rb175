require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader'
require 'yaml'

class User
  attr_reader :name, :email, :interests
  
  def initialize(name, email, interests)
    @name = name
    @email = email
    @interests = interests
  end

  def to_s
    "My name is #{name}! My email is #{email}! I like the following: #{interests}!"
  end
end

before do
  @users = []
  YAML.load_file('users.yaml').each do |name, attributes|
    @users << User.new(name, attributes[:email], attributes[:interests])
  end

  @user_count = @users.size
  @interest_count = @users.inject(0) {|sum, user| sum += user.interests.size}
end

helpers do

  def find_user(name_query)
    @users.select do |user|
      user.name.to_s == name_query
    end
  end

end

get "/" do
  erb :home
end

get "/users/:name" do
  @user = find_user(params['name']).first
  @other_users = (@users - [@user]).map {|user| user.name.to_s}
  
  erb :profile
end

get "/course/:course/instructor/:instructor" do |course, instructor|
  redirect "/users/jamy"
  puts "Hello"
end

#localhost:4567/course/234/instructor/jamison