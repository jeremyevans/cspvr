dev = ENV['RACK_ENV'] == 'development'

if dev
  require 'logger'
  logger = Logger.new($stdout)
end

require 'rack/unreloader'
Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Cspvr::Model', :logger=>logger, :reload=>dev, :autoload=>dev){Cspvr::App}
require_relative 'models'
Unreloader.require(File.expand_path('../app.rb', __FILE__)){'Cspvr::App'}
run(dev ? Unreloader : Cspvr::App.freeze.app)

unless dev
  begin
    require 'refrigerator'
  rescue LoadError
  else
    Refrigerator.freeze_core(:except=>['BasicObject'])
  end
end
