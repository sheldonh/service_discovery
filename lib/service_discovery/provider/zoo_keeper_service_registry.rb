require 'rubygems'
require_relative '../keyword_support'

module ServiceDiscovery

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

        ZooKeeperRegistration.new(zk, instance_path)
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

