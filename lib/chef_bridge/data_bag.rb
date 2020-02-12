module ChefBridge
  module DataBag
    @data_bags = {}
    @data_bag_locks = {}

    module_function

    def read(data_bag, data_bag_item, create_if_missing: false, refresh: nil, ignore_errors: false, silent: false, lock_data_bag: false, lock_timeout: 900, lock_timeout_message: nil)
      if lock_data_bag
        DataBag.lock(data_bag, data_bag_item, lock_timeout, lock_timeout_message, silent: silent)
        refresh = true
      end

      EasyIO.logger.debug "Retrieving data bag #{data_bag} #{data_bag_item}..."
      unless refresh || EasyFormat::Hash.safe_value(@data_bags, data_bag, data_bag_item).nil?
        EasyIO.logger.debug "Data bag content: #{@data_bags[data_bag][data_bag_item]}"
        return @data_bags[data_bag][data_bag_item]
      end

      EasyIO.logger.info "Requesting data bag #{data_bag} #{data_bag_item} from chef server..." unless silent
      data_bag_cmd = "knife data bag show #{data_bag} #{data_bag_item} --format json"
      stdout, stderr, _status = Open3.capture3(data_bag_cmd)
      unless stderr.empty? || ignore_errors || (stderr.include?('The object you are looking for could not be found') && create_if_missing)
        raise "Failed to retrieve data bag: #{stderr}\nKnife command: #{data_bag_cmd}"
      end
      @data_bags[data_bag] = {} if @data_bags[data_bag].nil?
      EasyIO.logger.debug 'Parsing results of data bag request...'
      @data_bags[data_bag][data_bag_item] = stdout.empty? ? { 'id' => data_bag_item } : JSON.parse(stdout.sub(/[^{\[]*/, ''))
      EasyIO.logger.debug "Data bag content: #{JSON.pretty_generate(@data_bags[data_bag][data_bag_item])}"
      @data_bags[data_bag][data_bag_item]
    end

    def push(data_bag, data_bag_item, content, unlock_data_bag: true, silent: false)
      data_bag_file = "#{ChefBridge.config['paths']['cache']}/data_bags/#{data_bag}/#{data_bag_item}.json"
      FileUtils.mkdir_p(::File.dirname(data_bag_file))
      ::File.write(data_bag_file, content.to_json)
      script = "knife data bag from file #{data_bag} #{data_bag_file}"
      EasyIO.logger.info "Pushing data bag #{data_bag} #{data_bag_item}..." unless silent
      EasyIO.execute_out(script, exception_exceptions: [/Updated data_bag_item\[#{data_bag}::#{data_bag_item}\]/]) # run knife data bag
      unlock(data_bag, data_bag_item) if unlock_data_bag
      EasyIO.logger.warn "Be sure to update the data bag in git if this is not a temporary change!\nA copy of the data bag can be found at #{data_bag_file}" unless silent
      @data_bags[data_bag] = {} if @data_bags[data_bag].nil?
      @data_bags[data_bag][data_bag_item] = content # Keep the data bag up to date in memory
    end

    def unlock_all
      @data_bag_locks.each { |_key, lock_file| lock_file.close }
    end

    def unlock(data_bag, data_bag_item)
      @data_bag_locks["#{data_bag}_#{data_bag_item}"].close
    end

    def lock(data_bag, data_bag_item, lock_timeout, lock_timeout_message = nil, silent: false)
      EasyIO.logger.info "Locking data bag #{data_bag} #{data_bag_item}..." unless silent
      lock_file = "#{ChefBridge.config['paths']['cache']}/data_bag_locks/#{data_bag}/#{data_bag_item}.lck"
      ::FileUtils.mkdir_p(::File.dirname(lock_file)) unless ::File.directory?(::File.dirname(lock_file))
      elapsed_sec = 0
      @data_bag_locks["#{data_bag}_#{data_bag_item}"] = ::File.open(lock_file, File::RDWR | File::CREAT)
      while lock_timeout >= elapsed_sec
        lock_success = @data_bag_locks["#{data_bag}_#{data_bag_item}"].flock(File::LOCK_EX | File::LOCK_NB)
        return if lock_success
        EasyIO.logger.info "Waiting for another task to unlock data bag #{data_bag} #{data_bag_item}...\nIf no other processes are running, delete #{lock_file}..." if (elapsed_sec += 1) % 15 == 0
        sleep(1)
      end
      @data_bag_locks["#{data_bag}_#{data_bag_item}"].close
      @data_bag_locks["#{data_bag}_#{data_bag_item}"] = nil
      raise "#{lock_timeout_message || ''}Failed to access data bag #{data_bag} #{data_bag_item}! Another process has it locked!"
    end
  end
end
