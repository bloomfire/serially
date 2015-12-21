require 'spec_helper'

describe 'Simple class that includes Serially' do
  let(:simple) { SimpleClass.new }

  it 'should contain class methods included from Serially' do
    simple.class.should respond_to(:serially)
  end

  context 'instance' do
    it 'should contain instance methods included from Serially' do
      simple.should respond_to(:serially)
      simple.serially.should respond_to(:start!)
    end

    it 'should contains all the tasks' do
      simple.serially.tasks.map(&:name).should == [:enrich, :validate, :refund, :archive]
    end

    context 'instance methods' do
      it '#serially.start! should enqueue Serially::Worker job' do
        simple.serially.start!
        resque_jobs = Resque.peek(Serially::Worker.queue, 0, 10)
        resque_jobs.count.should == 1
        resque_jobs.first['class'].should == Serially::Worker.to_s
        resque_jobs.first['args'].should == [SimpleClass.to_s, simple.object_id]
      end
    end
  end

end