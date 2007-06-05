require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require File.expand_path(File.join(File.dirname(__FILE__), '../shared/scammable'))

describe Page, "class (has_scams :content, :sidebar)" do
  it 'should have scam_names [:content, :sidebar]' do
    Page.scam_names.should == [:content, :sidebar]
  end
end

describe_scam_associations Page, :content, :sidebar
