ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"
require_relative "../cms"

class CMSTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
    login
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def login
    {"rack.session" => { credentials_validated: true} }
  end

  def logout
    get "/", {}, {"rack.session" => { credentials_validated: false} }
  end

  def test_index
    create_doc "about.txt"
    create_doc "changes.txt"
    
    get "/", {}, login

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "text/html;charset=utf-8", last_response.headers["Content-Type"]
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'about.txt'
  end

  def test_redirect_to_login
    get "/"
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<form"
  end

  def test_valid_login
    post "/users/signin", { username: "developer", password: "password" }
    assert_equal true, session[:credentials_validated]
    
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as developer"
  end

  def test_invalid_login
    post "/users/signin", { username: "johndoe", password: "wrong" }
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Invalid Credentials"
    assert_includes last_response.body, "johndoe"
  end

  def test_sign_out_form
    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]
    assert_equal false, session[:credentials_validated]
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Username:"
  end

  def test_view_txt_doc
    create_doc "changes.txt", "these are some changes."

    get "/changes.txt", {}, login

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "these are some changes."
  end

  def test_view_md_doc
    create_doc "business.md", "this is my business."

    get "/business.md", {}, login

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "this is my business."
  end

  def test_doc_not_found
    get "/not_a_valid_file", {}, login
    assert_equal 302, last_response.status

    assert_equal "File 'not_a_valid_file' does not exist.", session[:message]

    get last_response["Location"]
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_editing_doc
    create_doc "bizness.md", "this is my business."

    get "/bizness.md/edit", {}, login
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<textarea"
  end

  def test_saving_doc_changes    
    create_doc "changes.txt", "these are some changes."

    post "/changes.txt", { new_file_content: "new and improved content" }, login
    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:message]

    get last_response["Location"]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new and improved content"
  end

  def test_add_new_file
    get "/new", {}, login
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, "<form"
  end

  def test_new_file_saved
    post "/new", { new_doc_name: "test_doc.txt" }, login
    assert_equal 302, last_response.status
    assert_equal "test_doc.txt was created.", session[:message]

    get last_response["Location"]

    get "/"
    assert_includes last_response.body, "test_doc.txt"
  end

  def test_empty_file_name_not_accepted
    post "/new", { new_doc_name: '' }, login
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required."
  end

  def test_file_without_extension_not_accepted
    post "/new", { new_doc_name: 'beanis' }, login
    assert_equal 422, last_response.status
    assert_includes last_response.body, "An extension is required."
  end

  def test_delete_file
    create_doc 'file_to_delete.txt'
    
    post "/file_to_delete.txt/delete", {}, login
    assert_equal 302, last_response.status

    assert_equal "file_to_delete.txt was deleted.", session[:message]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    refute_includes last_response.body, "file_to_delete.txt</a>"
  end
end