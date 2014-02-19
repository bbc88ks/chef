#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/dsl/reboot_pending"
require "spec_helper"

describe Chef::DSL::RebootPending do

  let(:node) { Chef::Node.new } 
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:recipe) { Chef::Recipe.new(nil, nil, run_context) }

  describe "reboot_pending?" do
    before do
      recipe.stub(:platform?).and_return(false)
      recipe.stub(:platform_family?).and_return(false)
    end

    describe "in a recipe" do
      context "platform is windows" do
        before do
          recipe.stub(:platform_family?).with('windows').and_return(true)
          recipe.stub(:registry_key_exists?).and_return(false)
          recipe.stub(:registry_value_exists?).and_return(false)
        end
  
        it 'should return true if "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations" exists' do
          recipe.stub(:registry_value_exists?).with('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations').and_return(true)
          expect(recipe.reboot_pending?).to be_true
        end
  
        it 'should return true if "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" exists and contains specific values' do
          recipe.stub(:registry_key_exists?).with('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired').and_return(true)
          recipe.stub(:registry_get_values).with('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired').and_return(
                [{:name => "9306cdfc-c4a1-4a22-9996-848cb67eddc3", :type => :dword, :data => 1}])
          expect(recipe.reboot_pending?).to be_true
        end
  
        it 'should return true if key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired" exists' do
          recipe.stub(:registry_key_exists?).with('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired').and_return(true)
          expect(recipe.reboot_pending?).to be_true
        end
  
        it 'should return true if value "HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile" contains specific data' do
          recipe.stub(:registry_key_exists?).with('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile').and_return(true)
          recipe.stub(:registry_get_values).with('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile').and_return(
                [{:name => "Flags", :type => :dword, :data => 3}])
          expect(recipe.reboot_pending?).to be_true
        end
  
        it 'should return true if the windows_reboot LWRP has requested a reboot' do
          node.run_state.stub(:[]).with(:reboot_requested).and_return(true)
          expect(recipe.reboot_pending?).to be_true
        end
      end
  
      context "platform is ubuntu" do
        before do
          recipe.stub(:platform_family?).with('ubuntu').and_return(true)
          recipe.stub(:platform?).with('ubuntu').and_return(true)
        end
  
        it 'should return true if /var/run/reboot-required exists' do
          File.stub(:exists?).with('/var/run/reboot-required').and_return(true)
          expect(recipe.reboot_pending?).to be_true
        end
  
        it 'should return false if /var/run/reboot-required does not exist' do
          File.stub(:exists?).with('/var/run/reboot-required').and_return(false)
          expect(recipe.reboot_pending?).to be_false
        end
      end
    end # describe in a recipe

    describe "in a resource" do
      it "can access reboot_pending?" do
        resource = Chef::Resource::new("Crackerjack::Timing", run_context)
        expect(resource).to respond_to(:reboot_pending?)
      end
    end # describe in a resource
  end
end


