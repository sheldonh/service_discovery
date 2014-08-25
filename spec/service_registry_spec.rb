require 'spec_helper'

$VERBOSE = nil
require 'zk'
require 'json'

module KeywordSupport
  def self.require!(scope, *keywords)
    (keywords.empty? ? enumerate(scope) : keywords).each do |keyword|
      eval(%Q{ #{keyword} or raise ArgumentError.new("missing #{keyword} keyword") }, scope)
    end
  end

  def self.import!(scope, *keywords)
    (keywords.empty? ? enumerate(scope) : keywords).each do |keyword|
      eval(%Q{ @#{keyword} = #{keyword} or raise ArgumentError.new("missing #{keyword} keyword") }, scope)
    end
  end

  def self.enumerate(scope)
    eval(%q{ method(__method__).parameters.select { |type, name| type == :key }.map { |type, name| name } }, scope)
  end
end

module ServiceDiscovery

  # API
  class ServiceRegistry

    def initialize(environment: nil, provider: provider)
      KeywordSupport.import! binding
    end

    def register_service(service_context: nil, instance: nil, uri: nil)
      KeywordSupport.require! binding

      @provider.register(environment: @environment, service_context: service_context, instance: instance, uri: uri)
    end

    def lookup_service_uri(service_context: nil)
      KeywordSupport.require! binding

      @provider.lookup(environment: @environment, service_context: service_context).sample[:uri]
    end

    def deregister_service(service_context: nil, instance: nil)
      KeywordSupport.require! binding

      @provider.deregister(environment: @environment, service_context: service_context, instance: instance)
    end

  end

  class ServiceRegistration
    attr_reader :uri

    def initialize(uri: nil, provider: nil)
      KeywordSupport.import! binding
    end

    def deregister
      @provider.deregister
    end
  end

  class ServiceContext
    attr_reader :domain_perspective, :service, :protocol

    def initialize(domain_perspective: nil, service: nil, protocol: nil)
      KeywordSupport.import! binding
    end
  end

  module Provider

    class ZooKeeperServiceRegistry

      class ZooKeeperRegistration
        def initialize(zoo_keeper, znode)
          @znode = znode
          @zoo_keeper = zoo_keeper
        end

        def deregister
          @zoo_keeper.delete(@znode, :ignore => :no_node)
        end
      end

      def initialize(hosts: hosts)
        KeywordSupport.import! binding
      end

      def register(environment: nil, service_context: nil, instance: nil, uri: nil)
        KeywordSupport.require! binding

        zk = ZK.new(@hosts)

        path = instances_path(environment, service_context)
        path.split("/").inject do |current, child|
          (current + "/" + child).tap { |znode| zk.create(znode, :ignore => :node_exists) }
        end

        instance_path = path + "/" + instance
        zk.create(instance_path, {uri: uri}.to_json, mode: :ephemeral)

        ServiceRegistration.new(uri: uri, provider: ZooKeeperRegistration.new(zk, instance_path))
      end

      def lookup(environment: nil, service_context: nil)
        KeywordSupport.require! binding

        zk = ZK.new(@hosts)
        path = instances_path(environment, service_context)
        zk.children(path).map { |instance| JSON.parse(zk.get(path + "/" + instance)[0], symbolize_names: true) }
      end

      def deregister(environment: nil, service_context: nil, instance: nil)
        KeywordSupport.require! binding

        zk = ZK.new(@hosts)
        zk.delete(instances_path(environment, service_context) + "/" + instance, :ignore => :no_node)
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
    ServiceDiscovery::ServiceContext.new(domain_perspective: 'crm', service: 'contacts', protocol: 'http')
  end

  def initialize(service_registration: nil)
    KeywordSupport.import! binding
  end

  def get_contacts(client_number: nil)
    KeywordSupport.require! binding
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
    KeywordSupport.import! binding
  end

  def get_invoice_recipients(client_number: nil)
    KeywordSupport.require! binding
    contacts = @provider.get_contacts(client_number: client_number)
    contacts.select { |c| c.role == 'billing' }
  end

end

class Contact

  attr_reader :email, :role

  def initialize(properties: nil)
    KeywordSupport.require! binding
    @email = properties[:email]
    @role = properties[:role]
  end

end

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
