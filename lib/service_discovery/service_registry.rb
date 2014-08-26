require 'rubygems'
require_relative './keyword_support'

module ServiceDiscovery

  class ServiceRegistry

    def initialize(provider: provider)
      KeywordSupport.import! binding
    end

    def register_permanently(service_component: nil)
      KeywordSupport.require! binding

      context = service_component.context
      @provider.register_permanently(environment: context.environment, name: context.name, version: context.version, uri: service_component.uri)
    end

    def lookup(service_context: nil)
      KeywordSupport.require! binding

      @provider.lookup(environment: service_context.environment, name: service_context.name, version: service_context.version).map do |o|
        ServiceComponent.new(context: service_context, uri: o.uri)
      end
    end

    def deregister(service_component: nil)
      KeywordSupport.require! binding

      context = service_component.context

      @provider.deregister(environment: context.environment, name: context.name, version: context.version, uri: service_component.uri)
    end

    def deregister_all(service_context: nil)
      KeywordSupport.require! binding

      @provider.deregister_all(environment: service_context.environment, name: service_context.name, version: service_context.version)
    end

  end

end
