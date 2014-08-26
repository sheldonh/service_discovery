require 'rubygems'
require_relative './keyword_support'

module ServiceDiscovery

  class ServiceRegistry

    def initialize(provider: provider)
      KeywordSupport.import! binding
    end

    def register_permanently(service_component: nil)
      KeywordSupport.require! binding

      @provider.register_permanently(service_context: service_component.context, uri: service_component.uri)
    end

    def lookup(service_context: nil)
      KeywordSupport.require! binding

      @provider.lookup(service_context: service_context).map do |o|
        ServiceComponent.new(context: service_context, uri: o.uri)
      end
    end

    def deregister(service_component: nil)
      KeywordSupport.require! binding

      context = service_component.context

      @provider.deregister(service_context: service_component.context, uri: service_component.uri)
    end

    def deregister_all(service_context: nil)
      KeywordSupport.require! binding

      @provider.deregister_all(service_context: service_context)
    end

  end

end
