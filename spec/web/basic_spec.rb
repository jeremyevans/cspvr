require_relative 'spec_helper'

describe 'login/logout process' do
  it "login error messages should be displayed" do
    login
    click_button 'Logout'
    page.current_path.must_equal '/login'
    fill_in 'Login', :with=>'b'
    click_button 'Login'
    find('.alert-danger').text.must_equal 'There was an error logging in'
    page.html.must_include 'no matching login'

    fill_in 'Login', :with=>'a'
    click_button 'Login'
    find('.alert-danger').text.must_equal 'There was an error logging in'
    page.html.must_include 'invalid password'

    fill_in 'Login', :with=>'a'
    fill_in 'Password', :with=>'12345'
    click_button 'Login'
    find('.alert-danger').text.must_equal 'There was an error logging in'
    page.html.must_include 'invalid password'
  end
end

