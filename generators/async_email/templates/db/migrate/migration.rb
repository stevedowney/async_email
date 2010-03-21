class CreateAsyncEmailTables < ActiveRecord::Migration
  def self.up
    create_table :ae_emails, :force => true do |t|
      t.string :from
      t.string :subject
      t.text :body_text
      t.string :body_text_filename
      t.text :body_html
      t.string :body_html_filename
      t.string :status
      t.datetime :delivery_attempted_at
      t.text :error_message
      t.timestamps
    end
    
    create_table :ae_recipients, :force => true do |t|
      t.integer :email_id, :null => false
      t.string :type, :null => false
      t.string :email_address, :null => false
      t.timestamps
    end
    
    create_table :ae_attachments, :force => true do |t|
      t.integer :email_id, :null => false
      t.string :content_filename, :null => false
      t.string :filename_in_message
      t.timestamps
    end
  end

  def self.down
    drop_table :ae_attachments
    drop_table :ae_recipients
    drop_table :ae_emails
  end
end
