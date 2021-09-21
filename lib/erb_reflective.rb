# frozen_string_literal: true

require 'erb'

# Override some ERB behaviour to make it reflect methods supported
# by an object that is passed to it
class ERBReflective < ERB
  # Simply store the object reference passed in
  # then call the superclass behaviour with our binding instead
  def result(other_object)
    @other_object = other_object
    super(binding)
  end

  def method_missing(meth, *args, &block)
    super unless respond_to_missing? meth
    @other_object&.send(meth, *args, &block)
  end

  def respond_to_missing?(meth)
    @other_object&.respond_to? meth
  end
end
