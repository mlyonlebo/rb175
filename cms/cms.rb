require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :sessions_secret, "secret"
end

before do
  session[:credentials_validated] ||= false
end

helpers do
  def capitalize(title)
    no_caps = [
      'a', 'an', 'the', 'for', 'and', 'nor', 'but', 'or', 
      'yet', 'so', "at", "around", "by", "after",  "along", 
      "for", "from", "of", "on", "to", "with", "without"
    ]

    result = []
    
    title.each_with_index do |word, idx| 
      unless no_caps.include?(word) && idx > 0
        result << word.capitalize
      else
        result << word
      end
    end

    result.join(' ')
  end
  
  def display_title(file_name)
    base_title = File.basename(file_name, ".txt").split('_')
    capitalize(base_title)
  end
end

def data_path
  if env["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_error_message(file)
  session[:message] = "File '#{file}' does not exist."
  redirect "/"
end

def load_file_content(file, path)
  extension = File.extname(path)

  if extension == '.txt'
    headers["Content-Type"] = "text/plain"
    File.read(path)
  elsif extension == ".md"
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(File.read(path))
  end    
end

def create_doc(name, content = '')
  File.open(File.join(data_path, name), 'w') do |file|
    file.write(content)
  end
end

def invalid_file_name?(file)
  if file == ''
    "A name is required."
  elsif File.extname(file) == ''
    "An extension is required."
  elsif file.include?(' ')
    "No spaces, please."
  end
end

def sign_out
  session[:credentials_validated] = false
  session.delete(:username)
  session[:message] = "You have been signed out."
end

def successful_sign_in(username)
  session[:credentials_validated] = true
  session[:username] = @username
  session[:message] = "Welcome!"
  redirect "/"
end

def redirect_unless_signed_in
  redirect "/users/signin" unless session[:credentials_validated]
end

def users
  credentials_path = if env["RACK_ENV"] == "test"
    File.expand_path("../test/users_test.yaml", __FILE__)
  else
    File.expand_path("../users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  stored_pw = users[username]
  return false unless users[username]
  BCrypt::Password.new(users[username]) == password
end

#load index of available files
get "/" do
  redirect_unless_signed_in
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map { |file_path| File.basename(file_path) }
  erb :index, layout: :layout
end

#load sign-in page
get "/users/signin" do
  erb :signin, layout: :layout
end

#credential validation for sign-in
post "/users/signin" do
  #valid_credentials = {'admin' => 'secret'}
  @username = params[:username]
  @password = params[:password]

  if valid_credentials?(@username, @password)
    successful_sign_in(@username)
  else
    session[:message] = "Invalid Credentials"
    erb :signin, layout: :layout
  end
end

#sign out
post "/users/signout" do 
  sign_out
  redirect "/"
end

#form to add a new document
get "/new" do
  redirect_unless_signed_in
  erb :new_doc, layout: :layout
end

#save new document to data folder
post "/new" do
  redirect_unless_signed_in
  file_name = params[:new_doc_name]
  error_message = invalid_file_name?(file_name)

  if error_message
    session[:message] = error_message
    status 422
    erb :new_doc 
  
  else
    new_doc = params[:new_doc_name]
    create_doc new_doc

    session[:message] = "#{new_doc} was created."
    redirect "/"
  end
end

#load specified file
get "/:file_name" do
  redirect_unless_signed_in
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  if File.file?(file_path)
    load_file_content(file_name, file_path)
  else
    load_error_message(file_name)
  end
end

#updates the file and redirects to the index page
post "/:file_name" do 
  redirect_unless_signed_in
  file_name = params[:file_name]
  new_content = params[:new_file_content]
  file_path = File.join(data_path, file_name)
  
  File.write(file_path, new_content)
  session[:message] = "#{file_name} has been updated."
  redirect "/"
end

#form to edit file contents
get "/:file_name/edit" do
  redirect_unless_signed_in
  @file_name = params[:file_name]
  path = File.join(data_path, @file_name)
  @file_content = File.read(path)
  erb :file_edit, layout: :layout
end

# post "/:file_name/edit/:transformation" do
#   redirect_unless_signed_in
#   @file_name = params[:file_name]
#   @transformation = params[:transformation]
#   path = File.join(data_path, @file_name)
#   @file_content = File.read(path)
# end

#delete a file
post "/:file_name/delete" do
  redirect_unless_signed_in
  file_name = params[:file_name]
  FileUtils.rm File.join(data_path, file_name)
  session[:message] = "#{file_name} was deleted."
  redirect "/"
end


