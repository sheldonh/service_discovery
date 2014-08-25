module ServiceDiscovery

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

end
