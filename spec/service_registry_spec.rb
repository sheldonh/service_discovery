require 'spec_helper'

$VERBOSE = 0
require 'zk'
require 'json'

module ServiceDiscovery

  # API
  class ServiceRegistry
    def initialize(environment: nil, provider: provider)
      @environment = environment or raise ArgumentError.new("missing environment keyword")
      @provider = provider
    end

    def register_service(service_context: nil, instance: nil, uri: nil)
      service_context or raise ArgumentError.new("missing service_context keyword")
      instance or raise ArgumentError.new("missing uri keyword")
      uri or raise ArgumentError.new("missing uri keyword")

      @provider.register(environment: @environment, service_context: service_context, instance: instance, uri: uri)
    end

    def lookup_service_uri(service_context: nil)
      service_context or raise ArgumentError.new("missing service_context keyword")

      uri = @provider.lookup(environment: @environment, service_context: service_context)
    end

    def connect_service_provider(provider_class: nil)
      provider_class or raise ArgumentError.new("missing provider_class keyword")

      service_context = provider_class.service_context
      uri = @provider.lookup(environment: @environment, service_context: service_context)
      service_registration = OldServiceRegistration.new(uri: uri, registry: self)
      provider_class.new(service_registration: service_registration)
    end
  end

  class ServiceContext

    attr_reader :domain_perspective, :service, :protocol

    def initialize(domain_perspective: nil, service: nil, protocol: nil)
      @domain_perspective = domain_perspective or raise ArgumentError.new("missing domain_perspective keyword")
      @service = service or raise ArgumentError.new("missing service keyword")
      @protocol = protocol or raise ArgumentError.new("missing protocol keyword")
    end

  end

  class OldServiceRegistration

    attr_reader :uri, :registry

    def initialize(uri: nil, registry: nil)
      @uri = uri or raise ArgumentError.new("missing uri keyword")
      @registry = registry or raise ArgumentError.new("missing registry keyword")
    end

  end

  module Provider

    class ZooKeeperServiceRegistry

      def initialize(hosts: hosts)
        @hosts = hosts or raise ArgumentError.new("missing hosts keyword")
      end

      def register(environment: nil, service_context: nil, instance: nil, uri: nil)
        environment or raise ArgumentError.new("missing environment keyword")
        service_context or raise ArgumentError.new("missing service_context keyword")
        instance or raise ArgumentError.new("missing instance keyword")
        uri or raise ArgumentError.new("missing uri keyword")

        zk = ZK.new(@hosts)
        path = instances_path(environment, service_context)
        path.split("/").inject do |current, child|
          (current + "/" + child).tap { |znode| zk.create(znode, :ignore => :node_exists) }
        end
        instance_path = path + "/" + instance
        zk.create(instance_path, {uri: uri}.to_json, mode: :ephemeral)

        ZooKeeperServiceRegistration.new(znode: instance_path, zoo_keeper: zk)
      end

      def deregister
        raise "not registered" unless registered?
        @zk.delete("/service/#{@service}/#{@environment}/instance/#{@instance}")
        @zk = nil
      end

      def lookup(environment: nil, service_context: nil)
        environment or raise ArgumentError.new("missing environment keyword")
        service_context or raise ArgumentError.new("missing service_context keyword")
        # do zookeeper stuff
        'https://crm.starjuice.net/client'
      end

      private

        def instances_path(environment, service_context)
          domain_perspective = service_context.domain_perspective
          service = service_context.service
          protocol = service_context.protocol
          [nil, "services", environment, domain_perspective, service, protocol, "instances"].join("/")
        end

    end

  end

end

class ContactServiceRestProvider

  def self.service_context
    ServiceDiscovery::ServiceContext.new(domain_perspective: 'crm', service: 'contact_details', protocol: 'http')
  end

  def initialize(service_registration: nil)
    @service_registration = service_registration or raise ArgumentError.new("missing service_registration keyword")
  end

  def get_contacts(client_number: nil)
    client_number or raise new ArgumentError.new("missing client_number keyword")
    # rest = Rest.new(@service_location)
    # json = rest.get("/client/#{client_number}/contacts")
    # JSON.parse(json).each do { |properties| Contact.new(properties: properties) }

    [ Contact.new(properties: {email: 'sheldonh@starjuice.net', role: 'billing'}) ]
  end

  def service_uri
    @service_registration.uri
  end

end

class ContactService

  def initialize(provider: nil)
    @provider = provider or raise ArgumentError.new("missing provider keyword")
  end

  def get_invoice_recipients(client_number: nil)
    client_number or raise ArgumentError.new("missing client_number keyword")
    contacts = @provider.get_contacts(client_number: client_number)
    contacts.select { |c| c.role == 'billing' }
  end

end

class Contact

  attr_reader :email, :role

  def initialize(properties: nil)
    properties or raise ArgumentError.new("missing properties keyword")
    @email = properties[:email]
    @role = properties[:role]
  end

end

module ServiceDiscovery

  describe ServiceRegistry do

    before(:each) do
      raise "ZK_HOST environment variable must point to test ZooKeeper instance:port" unless ENV['ZK_HOST']
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
      uri = subject.lookup_service_uri(service_context: service_context)
      expect(uri).to eql 'https://crm.starjuice.net/client'
    end

    it "creates a connected service provider" do
      provider = subject.connect_service_provider(provider_class: ContactServiceRestProvider)
      service = ContactService.new(provider: provider)
      contacts = service.get_invoice_recipients(client_number: 'C1234576890')
      expect(contacts.first.email).to eql 'sheldonh@starjuice.net'
    end

  end

end
