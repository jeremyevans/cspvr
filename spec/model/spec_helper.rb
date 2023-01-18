ENV["RACK_ENV"] = "test"

require_relative '../minitest_helper'
require_relative '../../models'
raise "test database doesn't end with test" unless Cspvr::DB.opts[:database] =~ /test\z/

if ENV['NO_AUTOLOAD']
  Cspvr::Model.freeze_descendents
  Cspvr::DB.freeze
end
