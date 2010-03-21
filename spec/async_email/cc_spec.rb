require File.dirname(__FILE__) + '/../spec_helper'

describe AsyncEmail::Cc do
  
  it "should have Recipient superclass" do
    AsyncEmail::Cc.superclass.should == AsyncEmail::Recipient
  end
  
end