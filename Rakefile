# Migrate

migrate = lambda do |env, version|
  ENV['RACK_ENV'] = env
  require_relative 'db'
  require 'logger'
  Sequel.extension :migration
  Cspvr::DB.loggers << Logger.new($stdout)
  Sequel::Migrator.apply(Cspvr::DB, 'migrate', version)
end

desc "Migrate test database to latest version"
task :test_up do
  migrate.call('test', nil)
end

desc "Migrate test database all the way down"
task :test_down do
  migrate.call('test', 0)
end

desc "Migrate development database to latest version"
task :dev_up do
  migrate.call('development', nil)
end

desc "Migrate development database to all the way down"
task :dev_down do
  migrate.call('development', 0)
end

desc "Migrate production database to latest version"
task :prod_up do
  migrate.call('production', nil)
end

# Shell

irb = proc do |env|
  ENV['RACK_ENV'] = env
  trap('INT', "IGNORE")
  dir, base = File.split(FileUtils::RUBY)
  cmd = if base.sub!(/\Aruby/, 'irb')
    File.join(dir, base)
  else
    "#{FileUtils::RUBY} -S irb"
  end
  sh "#{cmd} -r ./models"
end

desc "Open irb shell in test mode"
task :test_irb do 
  irb.call('test')
end

desc "Open irb shell in development mode"
task :dev_irb do 
  irb.call('development')
end

desc "Open irb shell in production mode"
task :prod_irb do 
  irb.call('production')
end

# Specs

spec = proc do |pattern, env={}|
  prev = {}
  env.each do |k,v|
    prev[k] = ENV[k]
    ENV[k] = v
  end
  sh "#{FileUtils::RUBY} -e 'ARGV.each{|f| require f}' #{pattern}"
  prev.each do |k,v|
    ENV[k] = v
  end
end

desc "Run all specs"
task :default => [:model_spec, :web_spec]

desc "Run model specs"
task :model_spec do
  spec.call('./spec/model/*_spec.rb')
end

desc "Run web specs"
task :web_spec => [:web_admin_spec, :web_collector_spec]

desc "Run web admin specs"
task :web_admin_spec do
  spec.call('./spec/web/*_spec.rb')
end

desc "Run web collector specs"
task :web_collector_spec do
  #spec.call('./spec/web/collector_spec.rb', 'CSPVR_COLLECTOR_ONLY'=>'1')

  # Support testing using a separate database user with only INSERT access
  # to the csp_reports table
  spec.call('./spec/web/collector_spec.rb', 'CSPVR_COLLECTOR_ONLY'=>'separate_user')
end

desc "Run specs with coverage"
task "coverage" do
  spec.call('./spec/model/*_spec.rb', 'COVERAGE'=>'model')
  spec.call('./spec/web/*_spec.rb', 'COVERAGE'=>'web_admin')
  spec.call('./spec/web/collector_spec.rb', 'CSPVR_COLLECTOR_ONLY'=>'separate_user', 'COVERAGE'=>'web_collector')
end

# Misc

desc "Annotate Sequel models"
task "annotate" do
  require 'sequel/annotate'
  ENV['RACK_ENV'] = 'development'
  require_relative 'models'
  Cspvr::DB.loggers.clear
  Sequel::Annotate.new(Cspvr::Application).annotate('models/application.rb')
  Sequel::Annotate.new(Cspvr::CspReport).annotate('models/csp_report.rb')
end
