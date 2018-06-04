require './collector'
run Cspvr::App.freeze.app

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core
end
