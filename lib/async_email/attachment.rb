module AsyncEmail #:nodoc:
  
  class Attachment < ActiveRecord::Base #:nodoc:
    set_table_name :ae_attachments
  
    def attach_to(message)
      message.add_file(:filename => filename, :content => content)
    end
  
    def filename
      filename_in_message || File.basename(content_filename)
    end
  
    def content
      File.read(content_filename)
    end
  
  end
  
end