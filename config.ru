dev = ENV['RACK_ENV'] == 'development'

if dev
  require 'logger'
  logger = Logger.new($stdout)
end

require 'rack/unreloader'
Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Cspvr::Model', :logger=>logger, :reload=>dev){Cspvr::App}
require_relative 'models'
Unreloader.require('app.rb'){'Cspvr::App'}
run(dev ? Unreloader : Cspvr::App.freeze.app)
