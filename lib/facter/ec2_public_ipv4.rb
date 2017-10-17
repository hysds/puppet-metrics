# ec2_public_ipv4.rb
Facter.add("ec2_public_ipv4") do
  setcode do
    %x{curl -s http://169.254.169.254/latest/meta-data/public-ipv4}.chomp
  end
end
