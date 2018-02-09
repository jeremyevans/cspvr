module Cspvr
class CspReport < Model
  dataset_module do
    where :active, :open

    def close!
      active.update(:open=>false)
    end

    def search(field, key, value)
      where(Sequel.pg_jsonb(field).contains(key=>value))
    end

    def date_hash
      reverse(:id).select_hash_groups(Sequel[:at].cast(Date).as(:at), :id)
    end

    def most_recent_date_hash(application_ids)
      where(:application_id=>application_ids).
        select_group(:application_id).
        select_append{max(:at).cast(Date).as(:date)}.
        as_hash(:application_id, :date)
    end
  end
end
end

# Table: csp_reports
# Columns:
#  id             | integer                     | PRIMARY KEY DEFAULT nextval('csp_reports_id_seq'::regclass)
#  application_id | integer                     | NOT NULL
#  open           | boolean                     | NOT NULL DEFAULT true
#  at             | timestamp without time zone | NOT NULL DEFAULT CURRENT_TIMESTAMP
#  request_env    | jsonb                       | NOT NULL
#  report         | jsonb                       | NOT NULL
# Indexes:
#  csp_reports_pkey                    | PRIMARY KEY btree (id)
#  csp_reports_all_application_at_idx  | btree (application_id, at DESC)
#  csp_reports_open_application_at_idx | btree (application_id, at DESC) WHERE open
#  csp_reports_report_idx              | gin (report)
#  csp_reports_request_env_idx         | gin (request_env)
# Foreign key constraints:
#  csp_reports_application_id_fkey | (application_id) REFERENCES applications(id)
