require_relative 'models'

require 'roda'
require 'tilt/sass'

module Cspvr
# App initialization that does not get reloaded
class BaseApp < Roda
  plugin :flash
  plugin :sessions,
    :cipher_secret=>ENV.delete('CSPVR_SESSION_CIPHER_SECRET'),
    :hmac_secret=>ENV.delete('CSPVR_SESSION_HMAC_SECRET'),
    #:cookie_options=>{:secure=>(ENV['RACK_ENV'] != 'test'), :path=>'/', :httponly=>true}, # Uncomment if only allowing https:// access
    :key => 'cspvr.session'

  plugin :rodauth, :csrf=>:route_csrf do
    db DB
    enable :login, :logout
    account_password_hash_column :password_hash
    title_instance_variable :@page_title
  end
  precompile_rodauth_templates
end unless defined?(BaseApp)

class App < BaseApp
  opts[:root] = File.dirname(__FILE__)

  plugin :default_headers,
    'Content-Type'=>'text/html',
    #'Strict-Transport-Security'=>'max-age=16070400;', # Uncomment if only allowing https:// access
    'X-Frame-Options'=>'deny',
    'X-Content-Type-Options'=>'nosniff',
    'X-XSS-Protection'=>'1; mode=block'

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self, 'https://maxcdn.bootstrapcdn.com'
    csp.form_action :self
    csp.base_uri :none
    csp.frame_ancestors :none
  end

  plugin :disallow_file_uploads
  plugin :route_csrf
  plugin :assets, :css=>'app.scss', :css_opts=>{:style=>:compressed, :cache=>false}, :timestamp_paths=>true
  plugin :render, :escape=>true
  plugin :multi_route
  plugin :symbol_views
  plugin :typecast_params

  plugin :path
  path(Application){|app, rest=""| "/application/#{app.id}#{rest}"}
  path(CspReport){|rep, rest=""| "/application/#{rep.application_id}/report/#{rep.id}#{rest}"}

  plugin :not_found do
    view(:content=>'<h1>File Not Found</h1>')
  end

  plugin :error_handler do |e|
    if e.is_a?(Roda::RodaPlugins::TypecastParams::Error)
      response.status = 400
      @page_title = 'Invalid Parameter Format'
      view(:content=>"<p>Parameter #{h e.param_name} is not in the expected format.</p>")
    else
      $stderr.puts "#{e.class}: #{e.message}"
      $stderr.puts e.backtrace
      view(:content=>'<h1>Internal Server Error</h1>')
    end
  end

  Unreloader.require(File.expand_path('../routes', __FILE__)){}

  route do |r|
    r.on "collect" do
      r.route(:collect)
    end

    r.assets
    check_csrf!
    r.rodauth
    rodauth.require_authentication
    r.multi_route

    r.root do
      @applications = application_ds.by_name.all
      @last_updates = CspReport.active.most_recent_date_hash(@applications.map(&:id))
      view 'index'
    end
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
