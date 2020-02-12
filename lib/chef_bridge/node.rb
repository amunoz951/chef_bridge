module ChefBridge
  module Node
    module_function

    def nodes_by_policy_name_and_group(policy_name, policy_group = ChefBridge.config['environment']['policy_group'], exclude_rundeck_disabled_nodes: true)
      knife_search_text = "policy_name:#{policy_name} AND policy_group:#{policy_group}"
      knife_search_text += ' AND !rundeck_disabled:true' if exclude_rundeck_disabled_nodes
      node_attributes(knife_search_text)
    end

    def nodes_by_recipe(*recipe_names, policy_group: ChefBridge.config['environment']['policy_group'], exclude_rundeck_disabled_nodes: true)
      knife_search_text = "(recipes:#{recipe_names.map { |r| r.downcase.gsub(':', '\:') }.join(' OR recipes:')}) AND policy_group:#{policy_group}"
      knife_search_text += ' AND !rundeck_disabled:true' if exclude_rundeck_disabled_nodes
      node_attributes(knife_search_text) # To get fqdns: .map{ |node| node['automatic']['fqdn'] }
    end

    def nodes_by_name(node_name)
      node_attributes("name:#{node_name}")
    end

    def nodes_by_hostname(hostname)
      node_attributes("hostname:#{hostname}")
    end

    def node_attributes(knife_search_text)
      EasyIO.logger.debug "Searching for nodes matching \"#{knife_search_text.gsub('\:', ':')}\"..."
      result = `knife search node \"#{knife_search_text}\" --format json`.strip # run knife search
      result.empty? ? {} : JSON.parse(result.sub(/[^{\[]*/, ''))['rows'] # each row is a node object
    end
  end
end
