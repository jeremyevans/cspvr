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
  Model.plugin :prepared_statements
  Model.plugin :subclasses unless ENV['RACK_ENV'] == 'development'

  unless defined?(Unreloader)
    require 'rack/unreloader'
    Unreloader = Rack::Unreloader.new(:reload=>false)
  end

  Unreloader.require('models'){|f| "Cspvr::" + Sequel::Model.send(:camelize, File.basename(f).sub(/\.rb\z/, ''))}

  if ENV['RACK_ENV'] == 'development'
    require 'logger'
    DB.loggers << Logger.new($stdout)
  else
    Model.freeze_descendents
    DB.freeze
  end
end
