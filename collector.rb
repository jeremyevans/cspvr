# The collector file is a stripped down application that only collects CSP
# reports and doesn't allow viewing of them.  This is useful if you want
# to separate/restrict access, such as using a different database user
# that can insert into the csp_reports table, but not have other access.

require_relative 'db'

require 'roda'

module Cspvr
DB.freeze

class App < Roda
  plugin :disallow_file_uploads
  plugin :hash_routes
  require_relative 'routes/collect'

  route do |r|
    r.hash_routes(:preauth)
  end
end
end
