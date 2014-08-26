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

      def register_permanently(environment: nil, name: nil, version: nil, uri: nil)
        KeywordSupport.require! binding

        ZK.open(@hosts) do |zk|
          path = instances_path(environment, name, version)
          path.split("/").inject do |current, child|
            (current + "/" + child).tap { |znode| zk.create(znode, :ignore => :node_exists) }
          end

          instance_path = path + "/" + CGI.escape(uri)
          zk.create(instance_path, {uri: uri}.to_json, mode: :persistent)
        end
      end

      def lookup(environment: nil, name: nil, version: nil)
        KeywordSupport.require! binding

        map_children(environment, name, version) do |path, data|
          ZooKeeperServiceComponent.new(uri: data[:uri])
        end
      end

      def deregister(environment: nil, name: nil, version: nil, uri: nil)
        KeywordSupport.require! binding

        ZK.open(@hosts) do |zk|
          zk.delete(instances_path(environment, name, version) + "/" + CGI.escape(uri), :ignore => :no_node)
        end
      end

      def deregister_all(environment: nil, name: nil, version: nil)
        KeywordSupport.require! binding

        map_children(environment, name, version) do |path, data|
          zk.delete(path, :ignore => :no_node)
        end
      end

      private

        def map_children(environment, name, version)
          ZK.open(@hosts) do |zk|
            path = instances_path(environment, name, version)
            (zk.children(path, :ignore => :no_node) || []).map do |child|
              begin
                json = zk.get(path + "/" + child)[0]
                data = JSON.parse(json, symbolize_names: true)
                yield path + "/" + child, data
              rescue ZK::Exceptions::NoNode
                # Concurrent delete
              end
            end
          end
        end

        def instances_path(environment, service, version)
          [nil, "services", environment, service, version].join("/")
        end

    end

  end

end

