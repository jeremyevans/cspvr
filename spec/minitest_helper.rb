require_relative 'coverage_helper'
ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'
require 'minitest/hooks/default'

class Minitest::HooksSpec
  around(:all) do |&block|
    Cspvr::DB.transaction(:rollback=>:always){super(&block)}
  end

  around do |&block|
    Cspvr::DB.transaction(:rollback=>:always, :savepoint=>true, :auto_savepoint=>true){super(&block)}
  end

  if defined?(Capybara)
    after do
      Capybara.reset_sessions!
      Capybara.use_default_driver
    end
  end
end
