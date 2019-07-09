require "new_user_ssh/version"

module NewUserSsh
  class Error < StandardError;
  end

  class CLI < Thor
    desc "new_user 1.2.3.4 john", "Create user john on server"

    def new_user(ip, user_name = "deployer")
      puts "Password for root@#{ip}"
      password = $stdin.gets.chomp
      ssh = ::Net::SSH.start(ip, "root", password: password)
      puts "Password for #{user_name}"
      user_password = $stdin.gets.chomp

      %x(ssh-keygen -t rsa -b 4096 -f ~/.ssh/#{ip} -N '')

      cmds = ["useradd -m #{user_name}",
              "echo #{user_name}:#{user_password} | /usr/sbin/chpasswd",
              "usermod -aG sudo #{user_name}",
              "apt-get update",
              "apt-get install -y zsh",
              "usermod -s /bin/zsh #{user_name}",
              "groupadd docker",
              "usermod -aG docker #{user_name}",
              "echo '#{user_name}  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" # don't ask sudo password
      ]

# userdel -r user

      cmd = cmds.join(" && ")
      puts cmd

      a = ssh.exec!(cmd) do |channel, stream, data|
        print data #if stream == :stdout
      end

# brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
      puts `sshpass -p "#{user_password}" ssh-copy-id -i ~/.ssh/#{ip}.pub #{user_name}@#{ip}`
    end

    desc "compress_docker_machine name", "make tar.gz for sharing docker machine config"
    def compress_docker_machine(name)
      machines = %x(ls ~/.docker/machine/machines).split("\n")
      unless machines.include? name
        puts "Machine #{name} not found. Try: #{machines}"
        return
      end

      path = "~/.docker/machine/machines/#{name}"
      puts path

      %x(cp -r #{path} machine-shared)

      file = File.open("machine-shared/config.json", "r")
      str =  file.read
      str.gsub!(ENV["USER"], 'username')
      File.open("machine-shared/config.json", "w") { |file| file.puts str}
      %x(tar -zcf machine-shared.tar.gz machine-shared)
      %x(rm -rf machine-shared)
    end
  end
end
