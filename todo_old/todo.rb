require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
#allows us to render ERB templates

configure do
  enable :sessions
  set :sessions_secret, 'secret'
end

before do
  session[:lists] ||= [] 
  @lists = session[:lists]
end

helpers do 
  def all_todos_complete?(list)
    list[:todos].size > 0 && list[:todos].all? {|todo| todo[:completed] == 'true'}
  end

  def todos_complete(list)
    result = 0
    list[:todos].each {|todo| result += 1 if todo[:completed] == 'true'}
    result
  end

  def sorted_lists
    @lists.sort_by do |list| 
      all_todos_complete?(list) ? 1 : 0
    end
  end
end

get "/" do
  @books = [
    { title: "Snow Crash", author: "Neil Stephenson", published: "1992" },
    { title: "Consider Phlebas", author: "Iain M Banks", published: "1987" }
  ]
  erb :quiz, layout: :layout
end

# get "/" do
#   redirect "/lists"
# end

# View list of lists
# get "/lists" do
#   erb :lists, layout: :layout
# end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @id = params[:id].to_i
  @list = @lists[@id]
  erb :list, layout: :layout
end

get "/lists/:index/new" do
  erb :new_todo, layout: :layout
end

def error_for_list(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list(list_name)

  if error 
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: params[:list_name], todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Edit an existing todo list
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = @lists[@id]
  erb :edit_list, layout: :layout
end

#delete an existing todo list
post '/lists/:id/destroy' do
  @lists.delete_at(params[:id].to_i)
  session[:success] = "The list has been deleted."
  redirect '/lists'
end

#delete an existing todo
post '/lists/:id/todos/:todo_id/destroy' do
  list_id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  @lists[list_id][:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{params[:id]}"
end

#update existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  
  @list = @lists[params[:id].to_i]
  error = error_for_list(list_name)

  if error 
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@id}"
  end
end

def error_for_todo(name, other_todos)
  if !(1..100).cover? name.strip.size
    "Todo name must be between 1 and 100 characters."
  elsif other_todos.any? {|todo| todo[:name] == name}
    "List name must be unique."
  end
end

#add a todo to existing list
post "/lists/:id/todos" do
  new_todo = params[:todo]
  existing_todos = @lists[params[:id].to_i][:todos]
  error = error_for_todo(new_todo, existing_todos)
  
  if error 
    session[:error] = error
    @list = @lists[params[:id].to_i]
    erb :list, layout: :layout
  else
    existing_todos << {name: new_todo, completed: 'false'}
    session[:success] = "The todo has been added."
    redirect "/lists/#{params[:id]}"
  end
end

#check a todo as completed
post "/lists/:list_id/todos/:todo_id/complete" do 
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  new_completion_status = params[:completed]
  todo = @lists[list_id][:todos][todo_id]
  todo[:completed] = new_completion_status
  session[:success] = "Todo '#{todo[:name]}' is #{new_completion_status == 'true' ? 'complete' : 'incomplete'}."
  redirect "/lists/#{list_id}"
end

#check all todos as complete for a given list
post "/lists/:list_id/todos/complete_all" do
  @list_id = params[:list_id].to_i
  @lists[@list_id][:todos].each {|hsh| hsh[:completed] = 'true'}
  session[:success] = "All todos have been marked complete."
  redirect "/lists/#{@list_id}"
end