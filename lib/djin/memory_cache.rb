# frozen_string_literal: true

module Djin
  class MemoryCache
    def initialize(hash_store = {})
      @hash_store = hash_store
    end

    def fetch(key)
      @hash_store[key] || @hash_store[key] = yield
    end

    def clear
      @hash_store = {}
    end
  end
end
