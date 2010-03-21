module AsyncEmail #:nodoc:
  # The Message class is the single point of interaction for all things
  # related to AsyncEmail.
  #
  # See the README[link:files/README_rdoc.html] for examples.
  class Message < ActiveRecord::Base
    set_table_name :ae_emails
  
    has_many :recipients, :dependent => :delete_all, :class_name => "AsyncEmail::Recipient", :foreign_key => :email_id
    has_many :tos, :class_name => "AsyncEmail::To", :foreign_key => :email_id
    has_many :ccs, :class_name => "AsyncEmail::Cc", :foreign_key => :email_id
    has_many :bccs, :class_name => "AsyncEmail::Bcc", :foreign_key => :email_id
    has_many :attachments, :dependent => :destroy, :class_name => "AsyncEmail::Attachment", :foreign_key => :email_id

    STATUS_QUEUED = 'queued'
    STATUS_SENT = 'sent'
    STATUS_ERROR = 'error'
    
    named_scope :queued, :conditions => {:status => STATUS_QUEUED}
    named_scope :limit, lambda { |limit| { :limit => limit } }
    
    # Message is an ActiveRecord class so new (and create, create!, save, save!, etc.) behave
    # as expected.
    #
    # The attributes you can set are:
    # * <tt>:to</tt> - "to" recipients (takes String or Array)
    # * <tt>:cc</tt> - "cc" (carbon copy) recipients (String or Array)
    # * <tt>:bcc</tt> - "bcc" (blind copy) recipients (String or Array)
    # * <tt>:subject</tt> - subject
    # * <tt>:body_text</tt> - plain text body content
    # * <tt>:body_text_filename</tt> - file that is the source of plain text body content
    # * <tt>:body_html</tt> - html body content
    # * <tt>:body_html_filename</tt> - file that is the source of html body content
    # * <tt>:files</tt> - full paths to attachments (Array or String).  See +add_file+ for
    #   finer-grained control over adding files
    #
    # One of <tt>:to, :cc, :bcc</tt> must be set for message to be valid.
    #
    # The attribute pairs (<tt>:body_text, :body_text_filename</tt>) and 
    # (<tt>:body_html, :body_html_filename</tt>) are mutually exclusive.
    #
    # The <tt>:status</tt> column is force to STATUS_QUEUED for new instances.
    def initialize(attributes_in = {})
      attributes = (attributes_in ||= {}).merge(:status => STATUS_QUEUED)
      super(attributes)
    end
    
    def to=(*addresses) #:nodoc:
      set_recipients(:to, *addresses)
    end
    
    def cc=(*addresses) #:nodoc:
      set_recipients(:cc, *addresses)
    end
    
    def bcc=(*addresses) #:nodoc:
      set_recipients(:bcc, *addresses)
    end
    
    def set_recipients(recipient_type, *addresses) #:nodoc:
      method = "add_#{recipient_type}"
      [addresses].flatten.each do |address|
        send(method, address)
      end
    end

    def body_text_content #:nodoc:
      body_text || (body_text_filename && File.read(body_text_filename))
    end
    
    def body_html_content #:nodoc:
      body_html || (body_html_filename && File.read(body_html_filename))
    end
    
    def add_to(address) #:nodoc:
      tos.build(:email_address => address)
    end

    def add_cc(address) #:nodoc:
      ccs.build(:email_address => address)
    end
  
    def add_bcc(address) #:nodoc:
      bccs.build(:email_address => address)
    end
  
    def files=(*filenames) #:nodoc:
      [filenames].flatten.each do |filename|
        add_file(filename)
      end
    end
    
    # Add a file attachment.  
    #
    # The _content_filename_ is the path to the the file
    # whose content should be attached to the message.
    #
    # The _filename_in_message_ is the name the file will be given in the message.
    # If omitted it will be <tt>File.basename(_content_filename_)</tt>.
    #
    # If you are not specifying _filename_in_message_ then you can set files in
    # the constructor using the <tt>:files</tt> attribute.
    def add_file(content_filename, filename_in_message = nil)
      attachments.build :content_filename => content_filename, :filename_in_message => filename_in_message
    end

    # Deliver this message.  Normally called by Message#deliver_messages which
    # manages which messages need to be sent, status, retention policies, etc.
    # This method will attemp to deliver the message regardless of status.
    #---
    # FIXME: (Timeout::Error) on sending
    # FIXME: Net::SMTPAuthenticationError    
    def deliver
      mail = mail_from_async_email
      mail.deliver
      sent!
    rescue Exception => e
      error!(e)
    end

    def sent! #:nodoc:
      update_status(STATUS_SENT)
    end
    
    def error!(exception) #:nodoc:
      error_message = [exception.class, exception.message].join("\n")
      logger.error "Error attempting to deliver: #{self.inspect}"
      logger.error error_message
      logger.error exception.backtrace.join("\n")
      update_attribute(:error_message, error_message)
      update_status(STATUS_ERROR)
    end
      
    def update_status(status) #:nodoc:
      update_attributes({
        :delivery_attempted_at => Time.now,
        :status => status
      })
    end
    
    # Returns a Mail::Message instance from an AsyncEmail::Message instance.
    def mail_from_async_email #:nodoc:
      returning Mail.new do |mail|
        #TODO: get from ocnfiguration
        mail.from = "stevey"
        tos.add_to(mail)
        ccs.add_to(mail)
        bccs.add_to(mail)
        mail.subject = subject
        mail.text_part = text_part
        mail.html_part = html_part
        attach_files_to(mail)
      end
    end

    # Attaches a file to the Mail::Message instance.
    def attach_files_to(message) #:nodoc:
      attachments.each { |attachment| attachment.attach_to(message) }
    end
  
    # Sets plain text body for Mail::Message instance.
    def text_part #:nodoc:
      body_text = self.body_text_content
      Mail::Part.new do
        body body_text
      end
    end
  
    # Sets html body for Mail::Message instance
    def html_part #:nodoc:
      body_html = self.body_html_content
      Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body body_html
      end
    end

    class << self
      
      # Deliver queued messages.  Will only attempt to send first _limit_ messages.
      def deliver_messages(limit = 100)
        queued.limit(limit).each do |message|
          message.deliver
        end
      end
      
      # Send a message to _recipient_ to verify that your configuration is correct.
      # 
      # Options are <tt>:subject</tt> and <tt>:body</tt>
      def deliver_test_message(recipient, options = {})
        subject = options[:subject] || "Testing AsyncEmail"
        body = options[:body] || "Test email sent at #{Time.now}"
        Mail.deliver do
          from    'steve downey'
          to      recipient
          subject subject
          body    body
        end
      end
    
    end
  
  end
  
end