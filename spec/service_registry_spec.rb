require 'spec_helper'

$VERBOSE = nil
require 'service_discovery/service_context'
require 'service_discovery/service_component'
require 'service_discovery/service_registry'
require 'service_discovery/provider/zoo_keeper_service_registry'
require 'zk'
require 'json'

module ServiceDiscovery

  describe ServiceRegistry do

    before(:each) do
      raise "ZK_HOST environment variable must point to test ZooKeeper instance:port" unless ENV['ZK_HOST']
      subject.deregister_all(service_context: contact_details_v1)
    end

    after(:each) do
      subject.deregister_all(service_context: contact_details_v1)
    end

    subject do
      provider = Provider::ZooKeeperServiceRegistry.new(hosts: ENV['ZK_HOST'])
      ServiceRegistry.new(provider: provider)
    end

    let(:contact_details_v1) { ServiceContext.new(environment: 'test', name: 'contact_details', version: '1') } # XXX semantic?

    it "registers, deregisters and looks up service components" do
      s1 = ServiceComponent.new(context: contact_details_v1, uri: 'https://server1.crm.starjuice.net/contacts')
      s2 = ServiceComponent.new(context: contact_details_v1, uri: 'https://server2.crm.starjuice.net/contacts')
      subject.register_permanently(service_component: s1)
      subject.register_permanently(service_component: s2)

      expect( subject.lookup(service_context: contact_details_v1) ).to match_array [ s1, s2 ]

      subject.deregister(service_component: s1)
      expect( subject.lookup(service_context: contact_details_v1) ).to match_array [ s2 ]

      subject.deregister(service_component: s2)
      expect( subject.lookup(service_context: contact_details_v1) ).to match_array [ ]
    end

  end

end
