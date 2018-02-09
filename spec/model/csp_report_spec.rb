require_relative 'spec_helper'

describe Cspvr::CspReport do
  before(:all) do
    account_id = Cspvr::DB[:accounts].insert(:email=>'a', :password_hash=>'a')
    @app = Cspvr::Application.create(:account_id=>account_id, :name=>'Test')
    @class = Cspvr::CspReport
    @rep = @app.add_csp_report(:request_env=>{'a'=>'b'}, :report=>{'c'=>'d'})
  end
  before do
    # Performance hack to prevent unnecessary queries
    @rep = @class.load(@rep.values.dup)
  end

  it ".active should return a dataset of open reports" do
    @class.active.all.must_equal [@rep]
    @rep.this.update(:open=>false)
    @class.active.all.must_equal []
  end

  it ".close! should close any open reports and return the number closed" do
    @class.close!.must_equal 1
    @class.active.all.must_equal []
    @class.close!.must_equal 0
  end

  it ".search should return a dataset with matching key/value pair in the given field" do
    @class.search(:report, 'c', 'd').all.must_equal [@rep]
    @class.search(:report, 'c', 'e').all.must_equal []
    @class.search(:report, 'b', 'd').all.must_equal []

    @class.search(:request_env, 'a', 'b').all.must_equal [@rep]
    @class.search(:request_env, 'b', 'b').all.must_equal []
    @class.search(:request_env, 'a', 'a').all.must_equal []
  end

  it ".date_hash should return a hash of csp reports by day" do
    @class.date_hash.must_equal(Date.today=>[@rep.id])
    rep2 = @app.add_csp_report(:request_env=>{'a'=>'b'}, :report=>{'c'=>'d'})
    @class.date_hash.must_equal(Date.today=>[rep2.id, @rep.id])
  end

  it ".most_recent_date_hash should return a hash of dates keyed by application id for given application ids" do
    @class.most_recent_date_hash([]).must_equal({})
    @class.most_recent_date_hash([@app.id]).must_equal(@app.id=>Date.today)
    @rep.update(:at=>Date.today - 1)
    @class.most_recent_date_hash([@app.id]).must_equal(@app.id=>Date.today-1)
    rep2 = @app.add_csp_report(:request_env=>{'a'=>'b'}, :report=>{'c'=>'d'})
    @class.most_recent_date_hash([@app.id]).must_equal(@app.id=>Date.today)
  end
end
