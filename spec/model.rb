ENV['NO_AUTOLOAD'] = '1'
Dir['./spec/model/*_spec.rb'].each{|f| require f}
