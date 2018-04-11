ENV["RACK_ENV"] = "test"

require 'capybara'
require 'capybara/dsl'
require 'rack/test'
require 'bcrypt'

require_relative '../minitest_helper'

Gem.suffix_pattern

require_relative(ENV["CSPVR_COLLECTOR_ONLY"] ? '../../collector' : '../../app')

raise "test database doesn't end with test" unless Cspvr::DB.opts[:database] =~ /test\z/

Capybara.app = Cspvr::App.freeze

class Minitest::HooksSpec
  include Rack::Test::Methods
  include Capybara::DSL

  def app
    Capybara.app
  end

  def login
    visit '/'
    page.current_path.must_equal '/login'
    page.title.must_equal 'CSPVR - Login'
    fill_in 'Login', :with=>'a'
    fill_in 'Password', :with=>'123456'
    click_button 'Login'
    page.current_path.must_equal '/'
  end

  before(:all) do
    Cspvr::DB[:accounts].as_default_user.insert(:id=>1, :email=>'a', :password_hash=>BCrypt::Password.create('123456', :cost=>4))
  end
end