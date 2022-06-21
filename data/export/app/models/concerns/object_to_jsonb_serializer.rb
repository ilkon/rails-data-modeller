# frozen_string_literal: true

class ObjectToJsonbSerializer
  def self.dump(obj)
    obj
  end

  def self.load(obj)
    { h: obj || {} }.with_indifferent_access[:h]
  end
end
