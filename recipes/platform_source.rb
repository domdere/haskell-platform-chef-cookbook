#
# Cookbook Name:: haskell
# Recipe:: platform::source
# Copyright 2012, Travis CI development team
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

case [node[:platform_name], node[:platform_version]]
when ["ubuntu", "11.10"] then
  include_recipe "haskell::ghc::source"
when ["ubuntu", "12.04"] then
  include_recipe "haskell::ghc::package"
end

require "tmpdir"

cabal_file = '/usr/local/bin/cabal'

installed_already = ::File.exists?(cabal_file)

td            = Dir.tmpdir
local_tarball = File.join(td, "haskell-platform-#{node.haskell.platform.version}.tar.gz")

source_url = if node.haskell.platform.source_url.nil? then
    "http://lambda.haskell.org/platform/download/#{node.haskell.platform.version}/haskell-platform-#{node.haskell.platform.version}.tar.gz"
else
    node.haskell.platform.source_url
end


remote_file(local_tarball) do
  source    source_url

  not_if do
    installed_already or ::File.exists?(local_tarball)
  end
end

# 2. Extract it
# 3. configure, make install
bash "build and install Haskell Platform" do
  user "root"
  cwd  "/tmp"

  code <<-EOS
    tar zfx #{local_tarball}
    cd `tar -tf #{local_tarball} | head -n 1`

    which ghc
    ghc --version

    ./configure
    make
    make install
    cd ../
    rm -rf `tar -tf #{local_tarball} | head -n 1`
    rm #{local_tarball}

    cabal update
    cabal install hunit c2hs
  EOS

  creates cabal_file

  not_if do
    installed_already
  end
end
