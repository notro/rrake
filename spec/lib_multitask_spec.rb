require 'rrake/multi_task'

describe Rake::MultiTask do
  
  before :each do
    Rake.clear_sessions true
    Rake.application
  end

  it "multitask threads should pick up the invoking session" do
    sessions = []
    app_objects = []
    Rake.set_session Rake.new_session 'multitask'
    t = multitask( :test => [:thread1, :thread2, :thread3] )
    task :thread1 do
      sessions << Rake.get_session
      app_objects << Rake.application
    end
    task :thread2 do
      sessions << Rake.get_session
      app_objects << Rake.application
    end
    task :thread3 do
      sessions << Rake.get_session
      app_objects << Rake.application
    end
    t.invoke
    sessions.join.should == 'multitask' * 3
    result = true
    app_objects.each { |app| result &= (app == Rake.application) }
    result.should == true
  end
  
end
