ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"


class AppTest < Minitest::Test
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

    get last_response["Location"] # request the page user was redirected to
    assert_equal 200, last_response.status
    assert_includes last_response.body, "nonexistant.txt does not exist"

    get "/" # reload the page
    refute_includes last_response.body, "nonexistant.txt does not exist"
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

    get "/changes.txt/edit"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea "
    assert_includes last_response.body, ">Save Changes</button>"
  end

  def test_updating_document
    create_document "changes.txt"

    post "/changes.txt", content: "I'm being tested"
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "changes.txt has been updated."

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "I'm being tested"
  end

  def test_new_document
    get "/new"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input "
    assert_includes last_response.body, ">Create</button>"
  end

  def test_document_name_required
    post "/create", filename: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A valid name and extension is required."
    post "/create", filename: "word"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A valid name and extension is required."
  end

  def test_creating_new_document
    post "/create", filename: "test_doc.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "test_doc.txt was created."

    get "/"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "test_doc.txt was created."
  end

  def test_delete_document
    create_document "delete_me.txt"

    post "/delete_me.txt/destroy"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "delete_me.txt has been deleted"

    get "/"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "delete_me.txt has been deleted"
    

  end
end
