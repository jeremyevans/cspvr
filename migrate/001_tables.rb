Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id
      String :email, :null=>false
      String :password_hash, :null=>false
      index Sequel.function(:lower, :email), :unique=>true, :name=>'accounts_email_uidx'
    end

    create_table(:applications) do
      primary_key :id
      foreign_key :account_id, :accounts, :null=>false
      String :name, :null=>false
      index [:account_id, :name], :unique=>true, :name=>'applications_account_name_uidx'
    end

    create_table(:csp_reports) do
      primary_key :id
      foreign_key :application_id, :applications, :null=>false
      TrueClass :open, :null=>false, :default=>true
      Time :at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      jsonb :request_env, :null=>false, :index=>{:type=>:gin, :name=>"csp_reports_request_env_idx"}
      jsonb :report, :null=>false, :index=>{:type=>:gin, :name=>"csp_reports_report_idx"}
      index [:application_id, Sequel[:at].desc], :where=>:open, :name=>"csp_reports_open_application_at_idx"
      index [:application_id, Sequel[:at].desc], :name=>"csp_reports_all_application_at_idx"
    end

    # If you want to support running the collector as a database user with
    # reduced permissions, uncomment this section and the section below.
    # This adds an exec_as_default_user database function on the test database
    # which will support running arbitrary SQL as the user how runs this
    # migration.  It can be used in the specs for running the collector as
    # a separate application with reduced permissions, and testing with the
    # CSPVR_COLLECTOR_ONLY=separate_user environment variable.
=begin
    if get{current_database.function}.end_with?('test')
      run <<SQL
CREATE FUNCTION exec_as_default_user(sql text) RETURNS void AS $$
BEGIN
EXECUTE sql;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;
SQL
      run "REVOKE ALL ON FUNCTION exec_as_default_user(text) FROM public"
      run "GRANT EXECUTE ON FUNCTION exec_as_default_user(text) TO cspvr_public" # Modify user as appropriate
    end

    run 'GRANT INSERT ON csp_reports TO cspvr_public' # Modify user as appropriate
    run 'GRANT USAGE ON csp_reports_id_seq TO cspvr_public' # Modify user as appropriate
=end
  end

  down do
=begin
    if get{current_database.function}.end_with?('test')
      run "DROP FUNCTION exec_as_default_user(text)"
    end
=end

    drop_table :csp_reports, :applications, :accounts
  end
end
