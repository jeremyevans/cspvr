# frozen_string_literal: true
require_relative 'spec_helper'

describe Cspvr::Application do
  before(:all) do
    @account_id = Cspvr::DB[:accounts].insert(:email=>'a', :password_hash=>'a')
    @class = Cspvr::Application
    @app = @class.create(:account_id=>@account_id, :name=>'Test')
  end

  it "csp_reports association should work" do
    rep1 = @app.add_csp_report(:request_env=>{'a'=>'b'}, :report=>{'c'=>'d'})
    @app.csp_reports.must_equal [rep1]
  end

  it ".by_name should order dataset by name" do
    @class.by_name.all.must_equal [@app]
    app2 = @class.create(:account_id=>@account_id, :name=>'Best')
    @class.by_name.all.must_equal [app2, @app]
  end
end
