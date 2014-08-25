module ServiceDiscovery

  class ServiceContext
    attr_reader :domain_perspective, :service, :protocol

    def initialize(domain_perspective: nil, service: nil, protocol: nil)
      KeywordSupport.import! binding
    end
  end

end
