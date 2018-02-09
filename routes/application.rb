module Cspvr
class App
  route 'application' do |r|
    r.is "edit", ["new", Integer] do |application_id|
      @application = application_id == "new" ? Application.new(:account_id=>account_id) : application_ds.with_pk!(application_id)

      r.get do
        :application_form
      end

      r.post do
        @application.set(:name=>typecast_params.nonempty_str('name'))
        handle_validation_failure(:application_form, "There was an error saving the application") do
          @application.save
        end
        flash[:notice] = "Application #{application_id == 'new' ? 'Created' : 'Updated'}: #{@application.name}"
        r.redirect path(@application)
      end
    end

    r.on Integer do |application_id|
      @application = application_ds.with_pk!(application_id)

      r.get true do
        @all = typecast_params.bool('all')
        ds = @application.csp_reports_dataset
        ds = ds.active unless @all
        @date_hash = ds.date_hash
        :application_reports
      end

      r.get 'generate_report' do
        response['Content-Security-Policy'] = "default-src 'none'; style-src 'self' https://maxcdn.bootstrapcdn.com; img-src 'self'; report-uri #{request.base_url}/collect/#{application_id}"
        :generate_report
      end

      r.is "search" do
        @search = true
        @field, @key, @value, @type = typecast_params.str!(%w'field key value type')
        case @field
        when 'report', 'request_env'
          @value = @value.to_i if @type == 'i'
          ds = @application.csp_reports_dataset.active.search(@field.to_sym, @key, @value)
        else
          response.status = 400
          next view(:content=>'<p>Invalid field value</p>')
        end

        r.get do
          @page_title = "Matching CSP Violation Reports for #{@application.name}"
          @date_hash = ds.date_hash
          :application_reports
        end

        r.post do
          num_closed = ds.close!
          flash[:notice] = "Closed #{num_closed} CSP Violation Reports for Application #{@application.name}"
          r.redirect path(@application)
        end
      end

      r.on "report", Integer do |report_id|
        @report = @application.csp_reports_dataset.with_pk!(report_id)

        r.get true do
          :csp_report
        end

        r.post "close" do
          @report.this.active.close!
          flash[:notice] = "Closed CSP Violation Report #{@report.id} for Application #{@application.name}"
          r.redirect path(@application)
        end
      end
    end
  end
end
end
