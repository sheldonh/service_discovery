require 'rubygems'
require_relative './keyword_support'

module ServiceDiscovery

  class ServiceRegistry

    class ServiceRegistration
      attr_reader :uri

      def initialize(uri: nil, provider: nil)
        KeywordSupport.import! binding
      end

      def deregister
        @provider.deregister
      end
    end

    def initialize(environment: nil, provider: provider)
      KeywordSupport.import! binding
    end

    def register_service(service_context: nil, instance: nil, uri: nil)
      KeywordSupport.require! binding

      r = @provider.register(environment: @environment, service_context: service_context, instance: instance, uri: uri)
      ServiceRegistration.new(uri: uri, provider: r)
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

end
