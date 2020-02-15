module ChefBridge
  module_function

  def config
    @config ||= EasyJSON.config(defaults: defaults)
  end

  def defaults
    {
      'environment' => {
        'policy_group' => nil,
      },
      'paths' => {
        'cache' => Dir.tmpdir,
      },
    }
  end
end
