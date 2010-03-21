require File.dirname(__FILE__) + '/../spec_helper'

describe AsyncEmail::To do
  
  it "should have Recipient superclass" do
    AsyncEmail::To.superclass.should == AsyncEmail::Recipient
  end
  
end