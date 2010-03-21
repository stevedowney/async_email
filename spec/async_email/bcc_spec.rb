require File.dirname(__FILE__) + '/../spec_helper'

describe AsyncEmail::Bcc do
  
  it "should have Recipient superclass" do
    AsyncEmail::Bcc.superclass.should == AsyncEmail::Recipient
  end
  
end