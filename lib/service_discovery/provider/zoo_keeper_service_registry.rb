require 'rubygems'
require_relative '../keyword_support'
require 'cgi'
require 'json'
require 'zk'

module ServiceDiscovery

  module Provider

    class ZooKeeperServiceRegistry

      class ZooKeeperServiceComponent
        attr_reader :uri

        def initialize(uri: nil)
          KeywordSupport.import! binding
        end
      end

      def initialize(hosts: hosts)
        KeywordSupport.import! binding
      end

      def register_permanently(service_context: nil, uri: nil)
        KeywordSupport.require! binding

        create_context(service_context) do |zk|
          zk.create(component_path(service_context, uri), {uri: uri}.to_json, mode: :persistent)
        end
        nil
      end

      def lookup(service_context: nil)
        KeywordSupport.require! binding

        map_context(service_context) do |zk, path, data|
          ZooKeeperServiceComponent.new(uri: data[:uri])
        end
      end

      def deregister(service_context: nil, uri: nil)
        KeywordSupport.require! binding

        ZK.open(@hosts) do |zk|
          zk.delete(component_path(service_context, uri), :ignore => :no_node)
        end
        nil
      end

      def deregister_all(service_context: nil)
        KeywordSupport.require! binding

        map_context(service_context) do |zk, path, data|
          zk.delete(path, :ignore => :no_node)
        end
        nil
      end

      private

        def create_context(service_context)
          ZK.open(@hosts) do |zk|
            path = context_path(service_context)
            path.split("/").inject do |current, child|
              (current + "/" + child).tap { |znode| zk.create(znode, :ignore => :node_exists) }
            end

            yield zk, path
          end
        end

        def map_context(service_context)
          ZK.open(@hosts) do |zk|
            path = context_path(service_context)
            (zk.children(path, :ignore => :no_node) || []).map do |znode|
              begin
                json = zk.get(path + "/" + znode)[0]
                data = JSON.parse(json, symbolize_names: true)
                yield zk, path + "/" + znode, data
              rescue ZK::Exceptions::NoNode
                # Concurrent delete
              end
            end
          end
        end

        def context_path(context)
          [nil, "services", context.environment, context.name, context.version].join("/")
        end

        def component_path(context, uri)
          context_path(context) + "/" + CGI.escape(uri)
        end

    end

  end

end

