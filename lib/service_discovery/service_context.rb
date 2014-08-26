module ServiceDiscovery

  class ServiceContext

    include Comparable

    attr_reader :environment, :name, :version

    def initialize(environment: nil, name: nil, version: nil)
      KeywordSupport.import! binding
    end

    def <=>(other)
      if @environment == other.environment
        if @name == other.name
          @version <=> other.version
        else
          @name <=> other.name
        end
      else
        @environment <=> other.environment
      end
    end

  end

end
