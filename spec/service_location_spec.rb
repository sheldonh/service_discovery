require 'spec_helper'

$VERBOSE = nil
require 'service_discovery/service_location'
require 'service_discovery/service_registration'

module ServiceDiscovery
  describe ServiceLocation do
    before(:each) do
      raise "ZK_HOST environment variable must point to test ZooKeeper instance:port" unless ENV['ZK_HOST']
    end

    after(:each) do
      service.deregister if service.registered?
    end

    let(:service) { ServiceRegistration.new(service: 'zk-explore', environment: 'test', instance: 'test1', location: 'http://localhost') }

    subject { ServiceLocation.new(service: 'zk-explore', environment: 'test') }

    it "is locatable" do
      service.register
      subject.locate
      expect( subject.location ).to eql service.location
    end

    it "must handle the case where no instances are available"

  end
end
