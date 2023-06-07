# frozen_string_literal: true
module Cspvr
class App
  skip_re = /\A#{Regexp.union((<<-END).split)}/
		127.0.0.1
		about:blank
		android-webview
		chrome-extension://
		chromeinvoke://
		chromeinvokeimmediate://
		chromenull://
		localhost
		mbinit://
		ms-browser-extension
		mx://
		mxjscall://
		none://
		opera://
		res://
		resource://
		safari-extension://
		safari-resource://
		webviewprogressproxy://
  END
  ps = DB[:csp_reports].returning(nil).prepare(:insert, :insert_csp, :application_id=>:$application_id, :request_env=>:$request_env, :report=>:$report)

  hash_branch :preauth, 'collect' do |r|
    r.post Integer do |application_id|
      input = env["rack.input"]
      begin
        report = JSON.parse(input.read)
      rescue JSON::ParserError
      end

      input.rewind

      valid = if report.is_a?(Hash)
        report = report['csp-report'] if report['csp-report'].is_a?(Hash)
        if report['violated-directive']
          !((uri = report['blocked-uri']) && uri =~ skip_re)
        end
      end

      unless valid
        response.status = 400
        next ''
      end

      request_env = {}
      env.each do |k,v|
        request_env[k] = v if k =~ /\A[A-Z]/
      end
      request_env.delete('HTTP_COOKIE')

      ps.call(:application_id=>application_id, :request_env=>Sequel.pg_jsonb(request_env), :report=>Sequel.pg_jsonb(report))
      ''
    end
  end
end
end

