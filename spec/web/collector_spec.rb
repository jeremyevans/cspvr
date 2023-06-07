# frozen_string_literal: true
require_relative 'spec_helper'

describe '/collect' do
  def check_count(n)
    if @test_collector
      @db.run <<END
SELECT exec_as_default_user('DO language plpgsql $$
DECLARE
  count int;
BEGIN
  SELECT count(*) INTO count FROM csp_reports;
  IF count != #{n} THEN
    RAISE ''Count does not match #{n}'';
  END IF;
END;
$$;')
END
    else
      @csps.count.must_equal n
    end
  end

  def check_report(rep)
    if @test_collector
      expect = @db.literal(Sequel.pg_jsonb(rep)).gsub("'", "''")
      @db.run <<END
SELECT exec_as_default_user('DO language plpgsql $$
DECLARE
  app_id int;
  rep jsonb;
BEGIN
  SELECT application_id INTO app_id FROM csp_reports ORDER BY id DESC;
  SELECT report INTO rep FROM csp_reports ORDER BY id DESC;
  IF app_id != #{@app_id} THEN
    RAISE ''Application ID does not match #{@app_id}'';
  END IF;
  IF rep != #{expect} THEN
    RAISE ''report does not match #{expect.gsub("'", "''")}'';
  END IF;
END;
$$;')
END
    else
      @csps.get([:application_id, :report]).must_equal [@app_id, rep]
    end
  end

  it "should allow submitting CSP violation reports" do
    @db = Cspvr::DB
    @csps = @db[:csp_reports].reverse(:id)
    @db[:applications].as_default_user.insert(:id=>1, :account_id=>1, :name=>'TestApp')
    @app_id = 1
    uri = "/collect/#{@app_id}"
    @test_collector = ENV["CSPVR_COLLECTOR_ONLY"] == 'separate_user'

    post(uri, '[]', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 400
    check_count(0)

    post(uri, '{}', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 400
    check_count(0)

    post(uri, '{"csp-report": {"violated-directive": "b", "blocked-uri": "about:blank"}}', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 400
    check_count(0)

    post(uri, '{"violated-directive": "a"}', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 200
    check_count(1)
    check_report("violated-directive"=>"a")

    post(uri, '{"csp-report": {"violated-directive": "b"}}', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 200
    check_count(2)
    check_report("violated-directive"=>"b")

    post(uri, '{"csp-report": {"violated-directive": "b", "blocked-uri": "https://foo"}}', {'CONTENT_TYPE' => 'application/json'})
    last_response.status.must_equal 200
    check_count(3)
    check_report("violated-directive"=>"b", "blocked-uri" => "https://foo")
  end
end
