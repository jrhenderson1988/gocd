/*
 * Copyright 2019 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.thoughtworks.go.plugin.domain.configrepo;

import com.thoughtworks.go.plugin.api.info.PluginDescriptor;
import com.thoughtworks.go.plugin.domain.common.Image;
import com.thoughtworks.go.plugin.domain.common.PluggableInstanceSettings;
import com.thoughtworks.go.plugin.domain.common.PluginConstants;
import com.thoughtworks.go.plugin.domain.common.PluginInfo;

public class ConfigRepoPluginInfo extends PluginInfo {

    private final Capabilities capabilities;

    public ConfigRepoPluginInfo(PluginDescriptor descriptor, Image image, PluggableInstanceSettings pluginSettings, Capabilities capabilities) {
        super(descriptor, PluginConstants.CONFIG_REPO_EXTENSION, pluginSettings, image);
        this.capabilities = capabilities;
    }

    public Capabilities getCapabilities() {
        return capabilities;
    }

}
