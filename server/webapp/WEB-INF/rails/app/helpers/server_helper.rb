#
# Copyright 2019 ThoughtWorks, Inc.
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

module ServerHelper
  def build_message(health_messages)
    messages = []

    if health_messages.errorCount() > 0
      messages << "#{health_messages.errorCount()} #{'error'.pluralize(health_messages.errorCount())}"
    end

    if health_messages.warningCount() > 0
      messages << "#{health_messages.warningCount()} #{'warning'.pluralize(health_messages.warningCount())}"
    end

    messages.join(' and ')
  end

end
