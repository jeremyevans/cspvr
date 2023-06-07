# frozen_string_literal: true
if suite = ENV.delete('COVERAGE')
  require 'coverage'
  require 'simplecov'

  SimpleCov.instance_exec do
    command_name suite
    enable_coverage :branch

    start do
      add_filter "/spec/"
      add_filter "/models.rb"
      add_filter "/db.rb"
      add_filter "/.env.rb"
      add_group('Missing'){|src| src.covered_percent < 100}
      add_group('Covered'){|src| src.covered_percent == 100}
    end
  end
end
