require 'spec_helper'

$VERBOSE = nil
require 'service_discovery/service_registration'
require 'zk'
require 'json'

module ServiceDiscovery
  describe ServiceRegistration do

    before(:each) do
      raise "ZK_HOST environment variable must point to test ZooKeeper instance:port" unless ENV['ZK_HOST']
    end

    after(:each) do
      subject.deregister if subject.registered?
    end

    let(:zk) { ZK.new(ENV["ZK_HOST"] || "localhost:2181") }

    subject { ServiceRegistration.new(service: 'zk-explore', environment: 'test', instance: 'test1', location: 'http://localhost') }

    it "registers and deregisters" do
      subject.register

      expect( JSON.parse(zk.get("/service/zk-explore/test/instance/test1")[0], symbolize_names: true)[:location] ).to eql 'http://localhost'

      subject.deregister

      expect( zk.exists?("/service/zk-explore/test/instance/test1") ).to be_falsey
    end

    it "must register before it can deregister" do
      expect { subject.deregister }.to raise_error(/not registered/)
    end

    it "can't deregister while deregistered" do
      subject.register
      subject.deregister
      expect { subject.deregister }.to raise_error(/not registered/)
    end

    it "can reregister" do
      subject.register
      subject.deregister
      subject.register
      expect( zk.exists?("/service/zk-explore/test/instance/test1") ).to be_truthy
    end

  end
end
