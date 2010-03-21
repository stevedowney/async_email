class AsyncEmailGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      
      # migration
      m.migration_template('db/migrate/migration.rb', 'db/migrate', :migration_file_name => 'create_async_email_tables')
      
      # directory = "public/stylesheets/tab_nav"
      # m.directory directory
      # template_dir = File.dirname(__FILE__) + "/templates"
      # Dir["#{template_dir}/#{directory}/*"].each do |absolute_path|
      #   relative_path = absolute_path.sub("#{template_dir}/", '')
      #   m.file relative_path, relative_path
      # end
    end
  end
end