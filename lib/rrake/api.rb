require 'grape'


module Rake
class API < Grape::API
  prefix 'api'
  version 'v1'
  
  helpers do
    def setup
      Rake.application.log_context = body["trace"] if body["trace"]
      Rake.application.log_context = params["trace"] if params["trace"]
      Rake.application.info "#{env["REQUEST_METHOD"]} #{env["REQUEST_URI"]}"
      if params[:name]
        params[:name] = URI.unescape(params[:name])
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
    
    def proc_from_json(str)
      proc_str = JSON.parse(str, :create_additions=>false)
      Rake.module_eval "Proc.new #{proc_str['data'][0]}", proc_str['data'][1], proc_str['data'][2]
    end
    
  end
  
  put "clear" do
    setup
    Rake.application.clear
  end

  get "tasks" do
    setup
    log_return Rake.application.tasks.collect { |t| t.name }
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
    
    get "file_exist" do
      setup
      log_return task.file_exist?
    end
    
    get "file_mtime" do
      setup
      log_return task.file_mtime.to_i
    end
    
    get "investigation" do
      setup
      log_return task.investigation
    end
    
    get "actions" do
      setup
      log_return task.actions.collect { |a| a.to_json }
    end
    
    put "delete" do
      setup
      log_return Rake.application.delete_task params[:name]
    end
    
    put "execute" do
      setup
      if body["env_var"]
        env = ENV.to_hash
        body["env_var"].each { |k,v| ENV[k] = v }
      end
      if body["args"]
        args = Rake::TaskArguments.new(body["args"].keys, body["args"].values)
      else
        args = nil
      end
      exit_status = [false, nil]
      exception = [false, nil]
      capture = Rake::CaptureOutput.new do
        begin
          task.execute args
        rescue SystemExit => e
          exit_status = [true, e.status]
        rescue Exception => e
          exception = [true, e.class.to_s, e.message, e.backtrace]
        end
      end
      if body["env_var"]
        body["env_var"].each_key { |k| ENV[k] = env[k] }
      end
      log_return "exception" => exception, "exit_status" => exit_status, "output" => capture.output
    end
    
    post "enhance" do
      setup
      Rake.application.debug2 "  data: #{body.inspect}"
      if body["block"]
        block = proc_from_json body["block"]
        task.enhance nil, &block
      end
      if body["deps"]
        task.enhance body["deps"]
      end
      log_return true
    end
    
    post "override_needed" do
      setup
      Rake.application.debug2 "  data: #{body.inspect}"
      error!("400 Bad request: missing block", 400) unless body["block"]
      block = proc_from_json body["block"]
      task.override_needed_block = block
      log_return task.override_needed_block.to_json
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
      task = Rake.application.define_task(klass, params[:name])
      log_return task.inspect
    end
    
  end
  
  
end
end