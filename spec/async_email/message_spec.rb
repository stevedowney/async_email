require File.dirname(__FILE__) + '/../spec_helper'

describe AsyncEmail::Message do
  
  before(:each) do
    @message = AsyncEmail::Message.new
  end
  
  it "should default to queued" do
    @message.status.should == AsyncEmail::Message::STATUS_QUEUED
  end
  
  it "should require a recipient" do
    email_address = 'foo@example.com'
    [:to=, :cc=, :bcc=].each do |setter|
      @message = AsyncEmail::Message.new
      @message.should_not be_valid
      @message.send(setter, email_address)
      @message.should be_valid
    end
  end
  
  it "should allow only one of body_text, body_text_filename" do
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_text => 'foo').should be_valid
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_text_filename => 'foo').should be_valid
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_text => 'foo', :body_text_filename => 'foo').should_not be_valid
  end
  
  it "should allow only one of body_html, body_html_filename" do
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_html => 'foo').should be_valid
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_html_filename => 'foo').should be_valid
    AsyncEmail::Message.new(:to => 'foo@example.com', :body_html => 'foo', :body_html_filename => 'foo').should_not be_valid
  end
  
  describe 'to' do
    
    it 'to_add' do
      @message.add_to('foo@example.com')
      @message.tos.first.email_address.should == 'foo@example.com'
    end
    
    it "to= string" do
      @message = AsyncEmail::Message.new(:to => 'foo@example.com')
      @message.tos.first.email_address.should == 'foo@example.com'
    end
  
    it "to= array" do
      @message = AsyncEmail::Message.new(:to => ['foo@example.com', 'bar@example.com'])
      @message.tos.map(&:email_address).should == ['foo@example.com', 'bar@example.com']
    end
  
  end
  
  describe 'cc' do
    
    it 'cc_add' do
      @message.add_cc('foo@example.com')
      @message.ccs.first.email_address.should == 'foo@example.com'
    end
    
    it "cc=" do
      @message = AsyncEmail::Message.new(:cc => 'foo@example.com')
      @message.ccs.first.email_address.should == 'foo@example.com'
    end
  
    it "cc= array" do
      @message = AsyncEmail::Message.new(:cc => ['foocc@example.com', 'barcc@example.com'])
      @message.ccs.map(&:email_address).should == ['foocc@example.com', 'barcc@example.com']
    end
  
  end
  
  describe 'bcc' do
    
    it 'bcc_add' do
      @message.add_bcc('foo@example.com')
      @message.bccs.first.email_address.should == 'foo@example.com'
    end
    
    it "bcc=" do
      @message = AsyncEmail::Message.new(:bcc => 'foo@example.com')
      @message.bccs.first.email_address.should == 'foo@example.com'
    end
  
    it "bcc= array" do
      @message = AsyncEmail::Message.new(:bcc => ['foobcc@example.com', 'barbcc@example.com'])
      @message.bccs.map(&:email_address).should == ['foobcc@example.com', 'barbcc@example.com']
    end
  
  end
  
  describe 'files' do
    
    it 'file_add content only' do
      @message.add_file('path/to/file.ext')
      @file = @message.attachments.first
      @file.content_filename.should == 'path/to/file.ext'
      @file.filename_in_message.should be_nil
    end
    
    it 'file_add content + filename' do
      @message.add_file('path/to/file.ext', 'myname.txt')
      @file = @message.attachments.first
      @file.content_filename.should == 'path/to/file.ext'
      @file.filename_in_message.should == 'myname.txt'
    end
    
    it "files= one file" do
      @message = AsyncEmail::Message.new(:files => 'foo.txt')
      @message.attachments.first.content_filename.should == 'foo.txt'
    end
  
    it "files= > one file" do
      @message = AsyncEmail::Message.new(:files => ['foo.txt', 'bar.txt'])
      @message.attachments.map(&:content_filename).should == ['foo.txt', 'bar.txt']
    end
  
  end
  
  describe 'body' do
    before(:each) do
      @body_text_file = "body text file"
      @body_html_file = '<b>html</b>'
    end
    
    it "should get body text from body_text" do
      @message.body_text = 'foo'
      @message.body_text_content.should == 'foo'
    end
    
    it "should get body text from body_text_filename" do
      File.should_receive(:read).with('btfn').and_return(@body_text_file)
      @message.body_text_filename = 'btfn'
      @message.body_text_content.should == @body_text_file
    end
    
    it "should get html text from html_text" do
      @message.body_html = 'html'
      @message.body_html_content.should == 'html'
    end
    
    it "should get html text from html_text_filename" do
      File.should_receive(:read).with('bhfn').and_return(@body_html_file)
      @message.body_html_filename = 'bhfn'
      @message.body_html_content.should == @body_html_file
    end
    
  end
  
  
end