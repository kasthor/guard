require 'guard/interactors/completion'

module Guard

  # Interactor that used readline for getting the user input.
  # This enables history support and auto-completion, but is
  # broken on OS X without installing `rb-readline` or using JRuby.
  #
  # @see http://bugs.ruby-lang.org/issues/5539
  #
  class ReadlineInteractor < Interactor
    include ::Guard::Completion

    # Template method for checking if the Interactor is
    # available in the current environment?
    #
    # @param [Boolean] silent true if no error messages should be shown
    # @return [Boolean] the availability status
    #
    def self.available?(silent = false)
      require 'readline'

      if defined?(RbReadline) || defined?(JRUBY_VERSION) || RbConfig::CONFIG['target_os'] =~ /linux/i
        true
      else
        ::Guard::UI.error 'The :readline interactor runs only fine on JRuby, Linux or with the gem \'rb-readline\' installed.' unless silent
        false
      end
    end
    
    # Initialize the interactor.
    #
    def initialize
      require 'readline'

      Readline.completion_proc = proc { |word| auto_complete(word) }

      begin
        Readline.completion_append_character = ' '
      rescue NotImplementedError
        # Ignore, we just don't support it then
      end
    end

    # Start the interactor.
    #
    def start
      store_terminal_settings if stty_exists?
      super
    end

    # Stop the interactor.
    #
    def stop
      super
      restore_terminal_settings if stty_exists?
    end

    # Read a line from stdin with Readline.
    #
    def read_line
      require 'readline'
      
      while line = Readline.readline(prompt, true)
        line.gsub!(/^\W*/, '')
        if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
          Readline::HISTORY.pop
        end

        process_input(line)
      end
    end

    # The current interactor prompt
    #
    # @return [String] the prompt to show
    #
    def prompt
      ::Guard.listener.paused? ? 'p> ' : '> '
    end

    private

    # Detects whether or not the stty command exists
    # on the user machine.
    #
    # @return [Boolean] the status of stty
    #
    def stty_exists?
      system('hash', 'stty')
    end

    # Stores the terminal settings so we can resore them
    # when stopping.
    #
    def store_terminal_settings
      @stty_save = `stty -g 2>/dev/null`.chomp
    end

    # Restore terminal settings
    #
    def restore_terminal_settings
      system('stty', @stty_save, '2>/dev/null')
    end
  end
end
