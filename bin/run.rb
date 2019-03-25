#!/usr/bin/env ruby

require "bundler/setup"
require "thor"
require 'net/ssh'
require "new_user_ssh"

NewUserSsh::CLI.start(ARGV)
