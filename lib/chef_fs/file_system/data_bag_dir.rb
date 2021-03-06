#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/data_bag_item'
require 'chef_fs/file_system/not_found_error'
require 'chef_fs/file_system/must_delete_recursively_error'
require 'chef_fs/data_handler/data_bag_item_data_handler'

module ChefFS
  module FileSystem
    class DataBagDir < RestListDir
      def initialize(name, parent, exists = nil)
        super(name, parent, nil, ChefFS::DataHandler::DataBagItemDataHandler.new)
        @exists = nil
      end

      def dir?
        exists?
      end

      def read
        # This will only be called if dir? is false, which means exists? is false.
        raise ChefFS::FileSystem::NotFoundError.new(self)
      end

      def exists?
        if @exists.nil?
          @exists = parent.children.any? { |child| child.name == name }
        end
        @exists
      end

      def identity_key
        'id'
      end

      def _make_child_entry(name, exists = nil)
        DataBagItem.new(name, self, exists)
      end

      def delete(recurse)
        if !recurse
          raise NotFoundError.new(self) if !exists?
          raise MustDeleteRecursivelyError.new(self), "#{path_for_printing} must be deleted recursively"
        end
        begin
          rest.delete_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new(self, $!)
          end
        end
      end
    end
  end
end
