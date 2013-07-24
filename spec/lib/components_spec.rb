require 'spec_helper'
require 'json'

require "#{$root}/lib/statuspage.rb"

describe "components" do
  it "should get a json of all the components", :vcr do
    a = StatusPage.new
    a.should_receive(:response)
    output = a.send(:get_components_json)
  end
  
  it "should show status of a specific component", :vcr do
    a = StatusPage.new
    output = capture_stdout { a.components("programming")}
    output.should =~ /Status of Programming/
  end
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end
