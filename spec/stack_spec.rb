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

  describe "when stack operation throws ValidationError" do
    before :each do
      @stack = Stack.new("stack")
      @cf_stack.should_receive(:exists?).and_return(true)
      File.should_receive(:read).and_return("template")
      @cf.should_receive(:validate_template).and_return({"valid" => true})
      @cf_stack.should_receive(:update).and_raise(AWS::CloudFormation::Errors::ValidationError)
    end

    it "apply should return Failed to signal the error" do
      @stack.apply(nil, nil).should be(:Failed)
    end
  end

  describe "when stack operation throws ValidationError because no updates are to be performed" do
    before :each do
      @stack = Stack.new("stack")
      @cf_stack.should_receive(:exists?).and_return(true)
      File.should_receive(:read).and_return("template")
      @cf.should_receive(:validate_template).and_return({"valid" => true})
      @cf_stack.should_receive(:update).and_raise(AWS::CloudFormation::Errors::ValidationError.new("No updates are to be performed."))
    end

    it "apply should return NoUpdate to signal the error" do
      @stack.apply(nil, nil).should be(:NoUpdates)
    end
  end

  describe "when stack update succeeds" do
    before :each do
      @stack = Stack.new("stack")
      @cf_stack.should_receive(:exists?).at_least(:once).and_return(true)
      File.should_receive(:read).and_return("template")
      @cf.should_receive(:validate_template).and_return({"valid" => true})
      @cf_stack.should_receive(:update).and_return(false)
      @cf_stack.should_receive(:events).and_return([])
      @cf_stack.should_receive(:status).at_least(:once).and_return("UPDATE_COMPLETE")
    end

    it "apply should return Succeeded" do
      @stack.apply(nil, nil).should be(:Succeeded)
    end
  end
end
