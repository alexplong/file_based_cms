ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"


class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    {"rack.session" => { username: "admin" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    create_document "history.txt"

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_viewing_text_document
    create_document "history.txt", "1993 - Yukihiro Matsumoto dreams up Ruby."

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_document_not_found
    get "/nonexistant.txt"
    assert_equal 302, last_response.status # assert redirection
    assert_equal session[:message], "nonexistant.txt does not exist."
  end

  def test_markdown_document
    create_document "about.md", "# Ruby is.."

    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is..</h1>"
  end

  def test_editing_document
    create_document "changes.txt"

    get "/changes.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea "
    assert_includes last_response.body, ">Save Changes</button>"
  end

  def test_editing_document_logged_out
    create_document "changes.txt"

    get "/changes.txt/edit"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_updating_document
    create_document "changes.txt"

    post "/changes.txt", {content: "I'm being tested"}, admin_session
    assert_equal 302, last_response.status
    assert_equal session[:message], "changes.txt has been updated."

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "I'm being tested"
  end

  def test_updating_document_signed_out
    post "/changes.txt"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_new_document_form
    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input "
    assert_includes last_response.body, ">Create</button>"
  end

  def test_new_document_form_signed_out
    get "/new"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_document_name_required
    post "/create", {filename: ""}, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A valid name and extension is required."
  end

  def test_document_name_extension_required
    post "/create", {filename: "word"}, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A valid name and extension is required."
  end

  def test_creating_new_document
    post "/create", {filename: "test_doc.txt"}, admin_session
    assert_equal 302, last_response.status
    assert_equal session[:message], "test_doc.txt was created."
  end

  def test_creating_new_document_signed_out
    post "/create", {filename: "test_doc.txt"}
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_delete_document
    create_document "delete_me.txt"

    post "/delete_me.txt/destroy", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal session[:message], "delete_me.txt has been deleted."
  end

  def test_delete_document_signed_out
    create_document "delete_me.txt"

    post "/delete_me.txt/destroy"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_login_page
    get "/users/login"
    assert_equal 200, last_response.status
    assert_includes last_response.body, ">Sign In</button>"
    assert_includes last_response.body, "<input"
  end

  def test_user_login
    post "/users/login", {username: "admin", password: "secret"}
    assert_equal 302, last_response.status
    assert_equal session[:message], "Welcome!"
    assert_equal session[:username], "admin"
    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_user_login_bad_credentials
    post "/users/login", username: "guest", password: "shhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_logout
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as admin"

    post "/users/logout"
    assert_equal session[:message], "You have been signed out."

    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end
end
