require 'net/http'

module Typhoeus
  class LocalhostServer
    PORTS = [3000, 3001, 3002]

    def self.boot
      puts "Booting 3 test servers..."
      PORTS.each do |port|
        pid = fork do
          exec "ruby spec/servers/app.rb -p #{port}"
        end

        at_exit do
          Process.kill('INT', pid)
          begin
            Process.wait(pid)
          rescue Errno::ECHILD
            # ignore this error...I think it means the child process has already exited.
          end
        end

        Process.detach(pid)
      end

      Timeout.timeout(20) do
        loop do
          booted = PORTS.map { |port| booted?(port) }
          break unless booted.include?(false)
        end
        puts "Servers booted!"
      end
    end

    def self.booted?(port)
      res = ::Net::HTTP.get_response("localhost", '/__identify__', port)
      if res.is_a?(::Net::HTTPSuccess) or res.is_a?(::Net::HTTPRedirection)
        return true
      end
    rescue Errno::ECONNREFUSED, Errno::EBADF
      return false
    end
  end
end

Typhoeus::LocalhostServer.boot
