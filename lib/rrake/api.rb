require 'grape'


module Rake
class API < Grape::API
  prefix 'api'
  version 'v1'
  
  helpers do
  def capture_output
    s = StringIO.new
    oldstdout = $stdout
    oldstderr = $stderr
    $stdout = s
    $stderr = s
    yield
    s.string
  ensure
    $stdout = oldstdout
    $stderr = oldstderr
  end
  
    def setup
      Rake.application.log_context = body["trace"] if body["trace"]
      Rake.application.log_context = params["trace"] if params["trace"]
      Rake.application.info "#{env["REQUEST_METHOD"]} #{env["REQUEST_URI"]}"
      if params[:name]
        params[:name] = CGI::unescape(params[:name])
        params["name"] = params[:name]
      end
    end
    
    def log_return(o)
      Rake.application.info " => #{o.inspect}"
      o
    end
    
    def body
      return @body if @body
      data = request.body.read
      return {} if data == ""
      case env['api.format']
        when :json
          result = JSON.parse(data)
        else
          fail "unknown api.format #{env['api.format']}"
      end
      @body = result
    end
    
    def task
      return @task if @task
      begin
        @task = Rake.application[params[:name]]
      rescue RuntimeError => e
        if e.message.include? params[:name]
          Rake.application.warn "task not found '#{params[:name]}'"
          error!('404 Not Found', 404)
        else
          raise
        end
      end
      @task.log_context = body["trace"] if body["trace"]
      @task.log_context = params["trace"] if params["trace"]
      @task
    end
  end
  
  put "clear" do
    setup
    Rake.application.clear
  end

  get "tasks" do
    setup
    log_return Rake.application.tasks
  end
    
  resource "task/:name" do
    get "needed" do
      setup
      log_return task.needed?
    end
    
    get "timestamp" do
      setup
      log_return task.timestamp.to_i
    end
    
    get "investigation" do
      setup
      log_return task.investigation
    end
    
    put "execute" do
      setup
      output = capture_output do
        task.execute
      end
      log_return output
    end
    
    post "override_needed" do
      setup
      Rake.application.debug2 "  data: #{body.inspect}"
      error!("400 Bad request: missing block", 400) unless body["block"]
      task.override_needed_block = JSON.parse body["block"]
      log_return true
    end
    
    get "/" do
      setup
      log_return task.inspect
    end
  
    post "/" do
      setup
      Rake.application.debug2 "  data: #{body.inspect}"
      error!("400 Bad request: missing klass", 400) unless body["klass"]
      klass = eval "#{body["klass"]}"
      block = body["block"] ? JSON.parse(body["block"]) : nil
      task = Rake.application.define_task(klass, params[:name], &block)
      log_return task.inspect
    end
    
  end
  
  
end
end