require 'rrake/task.rb'
require 'rrake/early_time'

module Rake
  # #########################################################################
  # A FileTask is a task that includes time based dependencies.  If any of a
  # FileTask's prerequisites have a timestamp that is later than the file
  # represented by this task, then the file must be rebuilt (using the
  # supplied actions).
  #
  class FileTask < Task

    # Is this file task needed?  Yes if it doesn't exist, or if its time stamp
    # is out of date.
    def needed?
      ! file_exist? || out_of_date?(timestamp)
    end

    # Time stamp for file task.
    def timestamp
      if file_exist?
        file_mtime
      else
        Rake::EARLY
      end
    end

    def file_exist?
      if remote
        create_remote_task
        rget "file_exist"
      else
        File.exist?(name)
      end
    end
    
    def file_mtime
      if remote
        create_remote_task
        Time.parse rget "file_mtime"
      else
        File.mtime(name.to_s)
      end
    end

    private

    # Are there any prerequisites with a later time than the given time stamp?
    def out_of_date?(stamp)
      @prerequisites.any? { |n| application[n, @scope].timestamp > stamp}
    end

    # ----------------------------------------------------------------
    # Task class methods.
    #
    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        task_name
      end
    end
  end
end

