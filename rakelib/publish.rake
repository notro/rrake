# Optional publish task for Rake

begin
  require 'rrake/contrib/sshpublisher'
  require 'rrake/contrib/rubyforgepublisher'
  
  publisher = Rake::CompositePublisher.new
  publisher.add Rake::RubyForgePublisher.new('rrake', 'jimweirich')
  publisher.add Rake::SshFilePublisher.new(
    'umlcoop',
    'htdocs/software/rrake',
    '.',
    'rrake.blurb')
  
  desc "Publish the Documentation to RubyForge."
  task :publish => [:rdoc] do
    publisher.upload
  end
rescue LoadError => ex
  puts "#{ex.message} (#{ex.class})"
  puts "No Publisher Task Available"
end
