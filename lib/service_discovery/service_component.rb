require_relative './keyword_support'

module ServiceDiscovery

  class ServiceComponent
    include Comparable

    attr_reader :context, :uri

    def initialize(context: nil, uri: nil)
      KeywordSupport.import! binding
    end

    def <=>(other)
      @context == other.context ? @uri <=> other.uri : @context <=> other.context
    end

  end

end
