Airbrake.configure do |config|
  config.secure = false
  config.async do |notice|
    body = "Params: #{notice.parameters.inspect}\r\n"
    body << "Session: #{notice.session_data.inspect}\r\n"
    body << "Env: #{notice.cgi_data.inspect}\r\n"
    body << "URL: #{notice.url}\r\n" if notice.url
    body << "Component: #{notice.controller}\r\n" if notice.controller
    body << "Action: #{notice.action}\r\n" if notice.action
    body << "\r\n"
    body << "#{notice.error_message}\r\n\r\n"
    body << "#{notice.exception.backtrace.join("\r\n")}" if notice.exception.backtrace

    puts body

    Mail.new(:to => "1234", :from => "1234", :subject => "Error in #{notice.controller}::#{notice.action}", :body => body.strip).deliver
  end

  if defined?(Remotehue)
    Remotehue::Application.config.filter_parameters.each {|p| config.params_filters << p}
  end
end