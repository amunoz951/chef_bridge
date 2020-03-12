module ChefBridge
  module Node
    module_function

    def local(refresh: false)
      @node = ChefBridge::Node.search_by_hostname(Socket.gethostname).first if refresh
      @node ||= ChefBridge::Node.search_by_hostname(Socket.gethostname).first
    end

    def converge_nodes(policy_name, policy_group, credentials, node_name: nil, set_as_trusted_host: false)
      run_command_on_nodes('chef-client', policy_name, policy_group, credentials, node_name: node_name, set_as_trusted_host: set_as_trusted_host)
    end

    def run_command_on_nodes(command, policy_name, policy_group, credentials, node_name: nil, command_message: nil, shell_type: :cmd, tail_count: nil, set_as_trusted_host: false)
      servers = ChefBridge::Node.search_by_policy_name_and_group(policy_name, policy_group).map { |server| server['automatic']['fqdn'] }.select do |remote_host|
        node_name.nil? || node_name.strip.empty? || !(remote_host =~ /#{Regexp.escape(node_name)}/i).nil? # reject if the node name is set and it's not a match, otherwise, keep all
      end
      EasyIO.run_command_on_remote_hosts(servers, command, credentials, command_message: command_message, shell_type: shell_type, tail_count: tail_count, set_as_trusted_host: set_as_trusted_host)
    end

    # Multiple policy names can be separated with a forward slash
    def search_by_policy_name_and_group(policy_name, policy_group = ChefBridge.config['environment']['policy_group'], exclude_rundeck_disabled_nodes: true)
      policy_names = policy_name.gsub('/', ' OR policy_name:')
      knife_search_text = "(policy_name:#{policy_names}) AND policy_group:#{policy_group}"
      knife_search_text += ' AND !rundeck_disabled:true' if exclude_rundeck_disabled_nodes
      attributes(knife_search_text)
    end

    def search_by_recipe(*recipe_names, policy_group: ChefBridge.config['environment']['policy_group'], exclude_rundeck_disabled_nodes: true)
      knife_search_text = "(recipes:#{recipe_names.map { |r| r.downcase.gsub(':', '\:') }.join(' OR recipes:')}) AND policy_group:#{policy_group}"
      knife_search_text += ' AND !rundeck_disabled:true' if exclude_rundeck_disabled_nodes
      attributes(knife_search_text) # To get fqdns: .map{ |node| node['automatic']['fqdn'] }
    end

    def search_by_name(node_name)
      attributes("name:#{node_name}")
    end

    def search_by_hostname(hostname)
      attributes("hostname:#{hostname}")
    end

    def attributes(knife_search_text)
      EasyIO.logger.debug "Searching for nodes matching \"#{knife_search_text.gsub('\:', ':')}\"..."
      result = `knife search node \"#{knife_search_text}\" --format json`.strip # run knife search
      result.empty? ? {} : JSON.parse(result.sub(/[^{\[]*/, ''))['rows'] # each row is a node object
    end
  end
end
