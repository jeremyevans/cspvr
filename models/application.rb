module Cspvr
class Application < Model
  one_to_many :csp_reports, :order=>Sequel[:at].desc
  dataset_module do
    order :by_name, :name
  end
end
end

# Table: applications
# Columns:
#  id         | integer | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  account_id | integer | NOT NULL
#  name       | text    | NOT NULL
# Indexes:
#  applications_pkey              | PRIMARY KEY btree (id)
#  applications_account_name_uidx | UNIQUE btree (account_id, name)
# Foreign key constraints:
#  applications_account_id_fkey | (account_id) REFERENCES accounts(id)
# Referenced By:
#  csp_reports | csp_reports_application_id_fkey | (application_id) REFERENCES applications(id)
