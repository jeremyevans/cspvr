# frozen_string_literal: true
require_relative 'models'

require 'roda'
require 'strscan' # needed for Rack::Multipart::Parser

require 'tilt'
require 'tilt/erubi'
require 'tilt/string'

module Cspvr
# App initialization that does not get reloaded
# :nocov:
class BaseApp < Roda
# :nocov:
  opts[:check_dynamic_arity] = false
  opts[:check_arity] = :warn

  plugin :direct_call
  plugin :flash
  plugin :sessions,
    :secret=>ENV.delete('CSPVR_SESSION_SECRET'),
    #:cookie_options=>{:secure=>(ENV['RACK_ENV'] != 'test'), :path=>'/', :httponly=>true}, # Uncomment if only allowing https:// access
    :key => 'cspvr.session'

  plugin :rodauth, :csrf=>:route_csrf do
    db DB
    enable :login, :logout
    account_password_hash_column :password_hash
    title_instance_variable :@page_title
    login_input_type 'text'
  end
  precompile_rodauth_templates
end unless defined?(BaseApp)

# :nocov:
class App < BaseApp
# :nocov:
  opts[:root] = File.dirname(__FILE__)

  plugin :default_headers,
    'Content-Type'=>'text/html',
    #'Strict-Transport-Security'=>'max-age=16070400;', # Uncomment if only allowing https:// access
    'X-Frame-Options'=>'deny',
    'X-Content-Type-Options'=>'nosniff',
    'X-XSS-Protection'=>'1; mode=block'

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self
    csp.form_action :self
    csp.base_uri :none
    csp.frame_ancestors :none
  end

  plugin :disallow_file_uploads
  plugin :route_csrf
  plugin :assets, :css=>'app.scss', :css_opts=>{:style=>:compressed, :cache=>false}, :timestamp_paths=>true
  plugin :render, :escape=>true, :template_opts=>{:chain_appends=>true, :freeze=>true, :skip_compiled_encoding_detection=>true}
  plugin :hash_branches
  plugin :symbol_views
  plugin :Integer_matcher_max
  plugin :typecast_params_sized_integers, :sizes=>[64], :default_size=>64

  plugin :path

  logger = case ENV['RACK_ENV']
  when 'development', 'test' # Remove development after Unicorn 5.5+
    Class.new{def write(_) end}.new
  # :nocov:
  else
    $stderr
  # :nocov:
  end
  plugin :common_logger, logger

  # :nocov:
  if ENV['RACK_ENV'] == 'development'
    plugin :exception_page
    class RodaRequest
      def assets
        exception_page_assets
        super
      end
    end
  else
    def self.freeze
      Model.freeze_descendents
      DB.freeze
      super
    end
  end

  plugin :not_found do
    @page_title = 'File Not Found'
    view(:content=>'')
  end
  # :nocov:

  plugin :error_handler do |e|
    if e.is_a?(Roda::RodaPlugins::TypecastParams::Error)
      response.status = 400
      @page_title = 'Invalid Parameter Format'
      view(:content=>"<p>Parameter #{h e.param_name} is not in the expected format.</p>")
    else
      # :nocov:
      raise if ENV['RACK_ENV'] == 'test'

      $stderr.puts "#{e.class}: #{e.message}"
      $stderr.puts e.backtrace
      next exception_page(e, :assets=>true) if ENV['RACK_ENV'] == 'development'
      @page_title = 'Internal Server Error'
      view(:content=>'')
      # :nocov:
    end
  end

  if Unreloader.autoload?
    plugin :autoload_hash_branches
    autoload_hash_branch(:root, 'application', './routes/application.rb')
    autoload_hash_branch(:preauth, 'collect', './routes/collect.rb')
  end
  Unreloader.autoload(File.expand_path('../routes', __FILE__)){}

  route do |r|
    r.hash_branches(:preauth)
    r.assets
    r.rodauth
    check_csrf!
    rodauth.require_authentication

    r.root do
      @applications = application_ds.by_name.all
      @last_updates = CspReport.active.most_recent_date_hash(@applications.map(&:id))
      view 'index'
    end

    r.hash_branches(:root)
  end

  def handle_validation_failure(template, error_flash)
    yield
  rescue Sequel::ValidationFailed
    flash.now['error'] = error_flash
    response.status = 400
    response.write(view(template))
    request.halt
  end

  def url_escape(text)
    Rack::Utils.escape(text.to_s)
  end

  def account_id
    rodauth.session_value
  end

  def application_ds
    Application.where(:account_id=>account_id)
  end
end
end
