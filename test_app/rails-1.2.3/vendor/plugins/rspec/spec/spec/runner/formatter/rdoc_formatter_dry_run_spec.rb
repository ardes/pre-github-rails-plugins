require File.dirname(__FILE__) + '/../../../spec_helper.rb'

module Spec
module Runner
module Formatter
context "RdocFormatterDryRun" do
    setup do
        @io = StringIO.new
        @formatter = RdocFormatter.new(@io)
        @formatter.dry_run = true
    end
    specify "should not produce summary on dry run" do
        @formatter.dump_summary(3, 2, 1)
        @io.string.should == ""      
    end
end
end
end
end