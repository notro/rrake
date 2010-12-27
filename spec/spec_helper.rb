require 'lib/rrake'
require 'tmpdir'


require 'test/capture_stdout'
require 'test/in_environment'

module CommandHelp
  def command_line(*options)
    options.each do |opt| ARGV << opt end
    @app = Rake::Application.new
    def @app.exit(*args)
      throw :system_exit, :exit
    end
    @app.instance_eval do
      handle_options
      collect_tasks
    end
    @tasks = @app.top_level_tasks
    @app.options
  end
end


Rake.application.init
