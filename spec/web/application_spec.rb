require_relative 'spec_helper'

describe '/application' do
  it "should allow creating and editing applications and generating and closing CSP violation reports for those applications" do
    login
    click_link 'Create'
    page.title.must_equal 'CSPVR - Create Application'
    click_button 'Create Application'
    find('.alert-danger').text.must_equal 'There was an error saving the application'

    fill_in 'Name', :with=>'TestApp'
    click_button 'Create Application'
    find('.alert-success').text.must_equal 'Application Created: TestApp'

    click_link 'CSPVR'
    click_link 'TestApp'
    click_link 'Update Application'
    page.title.must_equal 'CSPVR - Update Application'

    fill_in 'Name', :with=>''
    click_button 'Update Application'
    find('.alert-danger').text.must_equal 'There was an error saving the application'

    fill_in 'Name', :with=>'TestApp2'
    click_button 'Update Application'
    find('.alert-success').text.must_equal 'Application Updated: TestApp2'

    click_link 'CSPVR'
    click_link 'TestApp2'
    page.title.must_equal 'CSPVR - TestApp2'
    click_link 'Generate CSP Violation Report'
    page.title.must_equal 'CSPVR - CSP Violation'
    report = Cspvr::Application.first.add_csp_report(:request_env=>{'FOO'=>'bar'}, :report=>{'a'=>'b'})

    click_link 'CSPVR'
    click_link 'TestApp2'
    find('caption').text.must_equal "Open CSP Violation Reports for TestApp2"
    page.all('td').map(&:text).must_equal [Date.today.to_s, report.id.to_s]
    click_link report.id.to_s
    page.title.must_equal "CSPVR - CSP Violation Report #{report.id} for TestApp2"
    find('.csp-report-time').text.must_equal "Violation Report Received At: #{report.at}"
    find('.csp-report').all('td').map(&:text).must_equal %w'a b'
    find('.csp-request_env').all('td').map(&:text).must_equal %w'FOO bar'

    r1 = Cspvr::Application.first.add_csp_report(:request_env=>{'FOO'=>'bar'}, :report=>{'a'=>'b'})
    r2 = Cspvr::Application.first.add_csp_report(:request_env=>{'FOO'=>'bar'}, :report=>{'a'=>'b'})
    r3 = Cspvr::Application.first.add_csp_report(:request_env=>{'BAR'=>'foo'}, :report=>{'a'=>'b'})

    click_button 'Close Report'
    find('.alert-success').text.must_include "Closed CSP Violation Report #{report.id} for Application TestApp2"
    report.refresh[:open].must_equal false

    page.all('td').map(&:text).must_equal [Date.today.to_s, [r3.id, r2.id, r1.id].join(' ')]
    click_link r2.id
    click_link 'bar'
    page.title.must_equal 'CSPVR - Matching CSP Violation Reports for TestApp2'
    find('.matching-criteria').text.must_equal 'Matching Criteria: FOO: bar'
    find('caption').text.must_equal "Matching CSP Violation Reports for TestApp2"
    page.all('td').map(&:text).must_equal [Date.today.to_s, [r2.id, r1.id].join(' ')]
    click_button 'Close All Matching CSP Violation Reports'
    find('.alert-success').text.must_include "Closed 2 CSP Violation Reports for Application TestApp2"

    page.all('td').map(&:text).must_equal [Date.today.to_s, r3.id.to_s]
    click_link 'Include Closed CSP Violation Reports'
    find('caption').text.must_equal "All CSP Violation Reports for TestApp2"
    page.all('td').map(&:text).must_equal [Date.today.to_s, [r3.id, r2.id, r1.id, report.id].join(' ')]
  end
end
