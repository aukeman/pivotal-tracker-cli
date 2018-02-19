module Utils

  def self.terminal_size
    if ENV.include?('COLUMNS') && ENV.include?('LINES')
      return ['COLUMNS', 'LINES'].map{|e| ENV[e]}.map(&:to_i)
    elsif command_exists?('tput')
      return ['cols', 'lines'].map{|a| `tput #{a}`}.map(&:to_i)
    elsif command_exists?('stty')
      return `stty size`.split.map(&:to_i).reverse
    else
      nil
    end
  end

  def self.command_exists? command
    ENV['PATH'].split(File::PATH_SEPARATOR).any? do |d|
      File.executable?(File.join(d,command))
    end
  end

end
