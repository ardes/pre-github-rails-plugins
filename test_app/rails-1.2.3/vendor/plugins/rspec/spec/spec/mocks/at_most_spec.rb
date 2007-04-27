require File.dirname(__FILE__) + '/../../spec_helper.rb'

module Spec
  module Mocks
    context "AtMost" do
      setup do
        @mock = Mock.new("test mock")
      end

      specify "should fail when at most n times method is called n plus 1 times" do
        @mock.should_receive(:random_call).at_most(4).times
        @mock.random_call
        @mock.random_call
        @mock.random_call
        @mock.random_call
        @mock.random_call
        lambda do
          @mock.rspec_verify
        end.should raise_error(MockExpectationError)
      end

      specify "should fail when at most once method is called twice" do
        @mock.should_receive(:random_call).at_most(:once)
        @mock.random_call
        @mock.random_call
        lambda do
          @mock.rspec_verify
        end.should raise_error(MockExpectationError)
      end

      specify "should fail when at most twice method is called three times" do
        @mock.should_receive(:random_call).at_most(:twice)
        @mock.random_call
        @mock.random_call
        @mock.random_call
        lambda do
          @mock.rspec_verify
        end.should raise_error(MockExpectationError)
      end

      specify "should pass when at most n times method is called exactly n times" do
        @mock.should_receive(:random_call).at_most(4).times
        @mock.random_call
        @mock.random_call
        @mock.random_call
        @mock.random_call
        @mock.rspec_verify
      end

      specify "should pass when at most n times method is called less than n times" do
        @mock.should_receive(:random_call).at_most(4).times
        @mock.random_call
        @mock.random_call
        @mock.random_call
        @mock.rspec_verify
      end

      specify "should pass when at most n times method is never called" do
        @mock.should_receive(:random_call).at_most(4).times
        @mock.rspec_verify
      end

      specify "should pass when at most once method is called once" do
        @mock.should_receive(:random_call).at_most(:once)
        @mock.random_call
        @mock.rspec_verify
      end

      specify "should pass when at most once method is never called" do
        @mock.should_receive(:random_call).at_most(:once)
        @mock.rspec_verify
      end

      specify "should pass when at most twice method is called once" do
        @mock.should_receive(:random_call).at_most(:twice)
        @mock.random_call
        @mock.rspec_verify
      end

      specify "should pass when at most twice method is called twice" do
        @mock.should_receive(:random_call).at_most(:twice)
        @mock.random_call
        @mock.random_call
        @mock.rspec_verify
      end

      specify "should pass when at most twice method is never called" do
        @mock.should_receive(:random_call).at_most(:twice)
        @mock.rspec_verify
      end
    end
  end
end