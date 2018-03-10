begin
  require_relative '.env.rb'
rescue LoadError
end

require 'sequel/core'

# Delete CSPVR_DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  CSPVR_DATABASE_URL may contain passwords.
module Cspvr
  DB = Sequel.connect(ENV.delete('CSPVR_DATABASE_URL') || ENV.delete('DATABASE_URL'))
  DB.extension :pg_json
  Sequel.extension :pg_json_ops

  if ENV['RACK_ENV'] == 'test'
    # Define a as_default_user dataset method for running certain commands
    # a separate user with greater access.  Designed to allow testing code
    # that runs with lowered permissions.  Requires that the
    # exec_as_default_user database function has been added to the test
    # database.
    if ENV["CSPVR_COLLECTOR_ONLY"] == 'separate_user'
      module AsDefaultUser
        %w'insert update delete'.each do |meth|
          define_method(meth) do |*a|
            db.run "SELECT exec_as_default_user(#{literal(disable_insert_returning.send(:"#{meth}_sql", *a))})"
          end
        end
      end
      DB.extend_datasets do
        def as_default_user
          with_extend(AsDefaultUser)
        end
      end
    else
      DB.extend_datasets do
        def as_default_user
          self
        end
      end
    end
  end
end
