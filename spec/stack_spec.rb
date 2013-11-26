require 'cloudformer/stack'

describe Stack do
  before :each do
    @cf = double(AWS::CloudFormation)
    @cf_stack = double(AWS::CloudFormation::Stack)
    @collection = double(AWS::CloudFormation::StackCollection)
    AWS::CloudFormation.should_receive(:new).and_return(@cf)
    @collection.should_receive(:[]).and_return(@cf_stack)
    @cf.should_receive(:stacks).and_return(@collection)
  end
  describe "when deployed" do
    before :each do
      @stack = Stack.new("stack")
    end

    it "should report as the stack being deployed" do
      @cf_stack.should_receive(:exists?).and_return(true)
      @stack.deployed.should be
    end

    describe "#delete" do
      it "should return a true if delete fails" do
        pending
        @cf_stack.should_receive(:exists?).and_return(false)
        @cf_stack.should_receive(:status)
        @stack.delete.should be
      end
    end
  end

  describe "when stack is not deployed" do
    before :each do
      @stack = Stack.new("stack")
    end

    it "should report as the stack not being deployed" do
      @cf_stack.should_receive(:exists?).and_return(false)
      @stack.deployed.should_not be
    end
  end
end