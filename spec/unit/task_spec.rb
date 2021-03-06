require 'spec_helper'

describe 'Serially::Task' do
  let(:simple) { SimpleInstanceId.new('IamKey') }
  let(:easy) { EasyClass.new }
  context 'equality' do
    it 'tasks with identical names should be equal' do
      simple.serially.tasks[:enrich].should == :enrich
    end
    it 'tasks with identical names but different including class should not be equal' do
      simple.serially.tasks[:enrich].should == :enrich
      easy.serially.tasks[:enrich].should == :enrich
      simple.serially.tasks[:enrich].should_not == easy.serially.tasks[:enrich]
    end
  end
  context '#to_s' do
    it 'should return the name of the task' do
      simple.serially.tasks[:enrich].to_s.should == 'enrich'
    end
  end
  context '#run!' do
    context 'using instance method' do
      it 'should return true and message string when task returns true and provides message string' do
        status, msg, result_obj = simple.serially.tasks[:enrich].run!(simple)
        status.should == true
        msg.should == 'Enriched just fine'
        result_obj.should be_blank
      end
      it 'should return true and empty message string when task returns some value other than null or false' do
        status, msg = simple.serially.tasks[:validate].run!((simple))
        status.should == true
        msg.should == ''
      end
      it 'should return false and empty message string when task returns false' do
        status, msg, result_obj = simple.serially.tasks[:refund].run!((simple))
        status.should == false
        msg.should == 'failed'
        result_obj.should == {reason: 'external api', date: Date.today}
      end
      it 'should return false and a message with exception, if task raises exception' do
        status, msg, result_obj = simple.serially.tasks[:complete].run!((simple))
        status.should == false
        msg.should include("Serially: task 'complete' raised exception: Unexpected failure")
        result_obj.should be_kind_of(RuntimeError)
      end
    end

    context 'using block' do
      it 'should return false and empty message if task returns nil' do
        status, msg = simple.serially.tasks[:archive].run!((simple))
        status.should == false
        msg.should == ''
      end
    end
  end
end