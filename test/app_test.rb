ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../application"


class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def setup
    @path = File.expand_path("../..", __FILE__)
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_viewing_text_document
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
  get "/about.md"
  assert_equal 200, last_response.status
  assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  assert_includes last_response.body, "<h1>Ruby is..</h1>"
  end
end
