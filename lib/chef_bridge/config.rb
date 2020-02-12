module ChefBridge
  module_function

  def config
    @config ||= EasyJson.config(defaults: defaults)
  end

  def defaults
    {
      'environment' => {
        'policy_group' => nil,
      },
      'paths' => {
        'cache' => nil,
      },
    }
  end
end
