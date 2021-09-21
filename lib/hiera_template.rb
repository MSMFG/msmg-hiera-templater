# frozen_string_literal: true

require 'fileutils'
require 'facter'
require 'hiera'

require_relative 'erb_reflective'

# Templating handler object used by ERBReflective
class HieraTemplate
  DEFAULT_CONFIG = '/etc/puppet/hiera.yaml'

  def initialize(hiera_config = DEFAULT_CONFIG)
    @scope = Facter.to_hash # Time consuming, do it once if possible!
    # Just so we can handle old facter references starting ::
    legacy = @scope.map { |k, v| ["::#{k}", v] }
    @scope.merge!(Hash[legacy])
    @hiera = Hiera.new(config: hiera_config)
  end

  # Template render
  def render(content)
    @blocks = []
    rendered = ERBReflective.new(content, nil, '-').result(self)
    return rendered unless @blocks.any?

    # See custom_out
    @blocks.each { |block| block.call(rendered) }
    true
  end

  # Methods used by ERBReflective to access hiera data
  # See above, full content is not available until the template is rendered so
  # we only stash the block references that we are given and call it later
  def custom_out(&block)
    raise StandardError, 'custom_out requires a block argument' unless block_given?

    @blocks << block
  end

  # The DSL

  # If hiera does not exist we will try facter data in scope to unify the API
  def hiera(key, default = nil)
    @hiera.lookup(key, nil, @scope) || @scope.dig(*key.split('.')) || default
  end

  def hiera_hash(key, default = nil)
    @hiera.lookup(key, default, @scope, nil, :hash)
  end

  def hiera_array(key, default = nil)
    @hiera.lookup(key, default, @scope, nil, :array)
  end

  def mkdir_p(path, owner: nil, group: nil, mode: nil)
    custom_out do |_|
      FileUtils.mkdir_p(path)
      FileUtils.chown_R(owner, group, path) if owner || group
      FileUtils.chmod_R(mode, path) if mode
    end
  end

  def custom_file(path, owner: nil, group: nil, mode: nil)
    custom_out do |content|
      File.write(path, content)
      FileUtils.chown(owner, group, path) if owner || group
      FileUtils.chmod(mode, path) if mode
    end
  end
end
