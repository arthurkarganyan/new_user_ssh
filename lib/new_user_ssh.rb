require "new_user_ssh/version"

module NewUserSsh
  class Error < StandardError;
  end

  class CLI < Thor
    desc "new_user root@0.0.0.0 john", "Create user john on server"

    def new_user(ssh_string, user_name)
      user, ip = ssh_string.split("@")
      puts "Password for #{ssh_string}"
      password = $stdin.gets.chomp
      ssh = ::Net::SSH.start(ip, user, password: password)
      puts "Password for #{user_name}"
      user_password = $stdin.gets.chomp
      cmds = ["useradd -m #{user_name}",
              "echo #{user_name}:#{user_password} | /usr/sbin/chpasswd",
              "usermod -aG sudo #{user_name}",
              "apt-get install -y zsh",
              "usermod -s /bin/zsh #{user_name}"]

      # userdel -r user

      cmd = cmds.join(" && ")
      puts cmd

      a = ssh.exec!(cmd) do |channel, stream, data|
        print data #if stream == :stdout
      end

      # brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
      puts `sshpass -p "#{user_password}" ssh-copy-id -i ~/.ssh/id_rsa.pub #{user_name}@#{ip}`
    end
  end
end
