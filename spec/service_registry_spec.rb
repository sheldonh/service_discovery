require 'spec_helper'

$VERBOSE = nil
require 'service_discovery/service_context'
require 'service_discovery/service_registry'
require 'service_discovery/provider/zoo_keeper_service_registry'
require 'zk'
require 'json'

module ServiceDiscovery

  describe ServiceRegistry do

    before(:each) do
      raise "ZK_HOST environment variable must point to test ZooKeeper instance:port" unless ENV['ZK_HOST']
    end

    after(:each) do
      subject.deregister_service(service_context: service_context, instance: 'crm1')
    end

    let(:service_context) { ServiceDiscovery::ServiceContext.new(domain_perspective: 'crm', service: 'contact_details', protocol: 'http') }

    subject do
      provider = Provider::ZooKeeperServiceRegistry.new(hosts: ENV['ZK_HOST'])
      ServiceRegistry.new(environment: 'test', provider: provider)
    end

    it "registers a service uri" do
      registration = subject.register_service(service_context: service_context, instance: 'crm1', uri: 'https://crm.starjuice.net/client')
      expect(registration.uri).to eql 'https://crm.starjuice.net/client'
    end

    it "looks up a service uri" do
      subject.register_service(service_context: service_context, instance: 'crm1', uri: 'https://crm.starjuice.net/client')
      uri = subject.lookup_service_uri(service_context: service_context)
      expect(uri).to eql 'https://crm.starjuice.net/client'
    end

  end

end
