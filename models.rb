require_relative 'db'
require 'sequel'

module Cspvr
  Model = Class.new(Sequel::Model)
  Model.db = DB
  Model.def_Model(self)

  if ENV['RACK_ENV'] == 'development'
    Model.cache_associations = false
  end

  Model.plugin :auto_validations, :not_null=>:presence
  Model.plugin :pg_auto_constraint_validations
  Model.plugin :auto_restrict_eager_graph
  Model.plugin :require_valid_schema
  Model.plugin :subclasses unless ENV['RACK_ENV'] == 'development'

  unless defined?(Unreloader)
    require 'rack/unreloader'
    Unreloader = Rack::Unreloader.new(:reload=>false, :autoload=>!ENV['NO_AUTOLOAD'])
  end

  Unreloader.autoload(File.expand_path('../models', __FILE__)){|f| "Cspvr::" + Sequel::Model.send(:camelize, File.basename(f).sub(/\.rb\z/, ''))}

  if ENV['RACK_ENV'] == 'development'
    require 'logger'
    DB.loggers << Logger.new($stdout)
  end
end
